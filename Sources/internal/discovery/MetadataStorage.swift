//
//  MetadataStorage.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 6.11.2023.
//

import Foundation

public class MetadataStorage {
    
    private static let PREF_NAME = "musap"
    private static let SSCD_SET  = "sscd"
    
    /**
     * Set that contains all known key names
     */
    private static let KEY_ID_SET = "keyids"
    private static let SSCD_ID_SET  = "sscdids"
    
    /**
     * Prefix that storage uses to store key-speficic metadata.
     */
    private static let KEY_JSON_PREFIX = "keyjson_"
    private static let SSCD_JSON_PREFIX = "sscdjson_"
    
    private let userDefaults = UserDefaults.standard
    
    
    // Public initializer required or else iOS apps will think the class is internal
    public init() {}
    
    /// Store a MusapKey
    public func addKey(key: MusapKey, sscd: SscdInfo) throws {
        AppLogger.shared.log("Trying to store a key...")
        
        guard let keyId = key.getKeyId() else {
            AppLogger.shared.log("Can't store key, Key ID was nil", .error)
            throw MusapError.missingParam
        }
    
        // Create the key-specific store name using the prefix and the key ID
        let storeName = makeStoreName(keyId: keyId)
        
        AppLogger.shared.log("Storing key with ID \(keyId) - storeName: \(storeName)", .debug)
    
        // Encode the key to JSON and store it using the store name
        do {
            let keyJson = try JSONEncoder().encode(key)
            userDefaults.set(keyJson, forKey: storeName) // Use storeName to save the key JSON
            AppLogger.shared.log("Storing key with storename: \(storeName)")
        } catch {
            AppLogger.shared.log("Could not encode key to JSON: \(error)", .error)
            throw MusapException(MusapError.internalError)
        }
        
        // Insert the key ID into the set of known key names and save it
        var newKeyIds = getKeyIds()
        newKeyIds.insert(keyId)
        userDefaults.set(Array(newKeyIds), forKey: MetadataStorage.KEY_ID_SET)
        userDefaults.synchronize()
        
        //TODO: is this needed?
        try self.addSscd(sscd: sscd)
        
        AppLogger.shared.log("All key ID's: \(newKeyIds)")
    }
    
    /**
     List available MUSAP keys
     */
    public func listKeys() -> [MusapKey] {
        AppLogger.shared.log("Trying to list MUSAP keys")
        
        let keyIds = getKeyIds()
        var keyList: [MusapKey] = []

        for keyId in keyIds {
            if let keyData = userDefaults.data(forKey: makeStoreName(keyId: keyId)),
               let key = try? JSONDecoder().decode(MusapKey.self, from: keyData) {
                keyList.append(key)
            } else {
                AppLogger.shared.log("Missing key metadata JSON for key ID: \(keyId)")
            }
        }

        AppLogger.shared.log("Found \(keyList.count) MUSAP keys)")
        return keyList
    }
    
    public func listKeys(req: KeySearchReq) -> [MusapKey] {
        AppLogger.shared.log("Trying to list keys with search criteria")
        
        let keyIds = self.getKeyIds()
        var keyList = [MusapKey]()
        
        for keyId in keyIds {
            if let keyJson = self.getKeyJson(keyId: keyId) {
                if let jsonData = keyJson.data(using: .utf8) {
                    let decoder = JSONDecoder()

                    do {
                        let key = try decoder.decode(MusapKey.self, from: jsonData)
                        if (req.keyMatches(key: key)) {
                            keyList.append(key)
                        }
                    } catch {
                        AppLogger.shared.log("Error decoding JSON for keyID: \(keyId), error: \(error)", .error)
                    }
                }
            }

        }
        
        AppLogger.shared.log("Found \(keyList.count) keys")
        return keyList
    }
    
    /**
     Remove key metadata from storage
     */
    public func removeKey(key: MusapKey) -> Bool {
        guard let keyId = key.getKeyId() else {
            AppLogger.shared.log("Can't remove key. Key ID was nil")
            return false
        }
        
        var newKeyIds = getKeyIds()
        newKeyIds.remove(keyId)
        
        let newKeyIdsArray = Array(newKeyIds)
        
        AppLogger.shared.log("Removed key. Current key ID's: \(newKeyIdsArray)")
        
        do {
            let keyStoreName = try makeStoreName(key: key)
            
            if let keyJson = try? JSONEncoder().encode(key) {
                userDefaults.set(newKeyIdsArray, forKey: MetadataStorage.KEY_ID_SET)
                userDefaults.set(keyJson, forKey: keyStoreName)
                userDefaults.removeObject(forKey: makeStoreName(keyId: keyId))
                
                AppLogger.shared.log("Successfully removed a key with ID: \(keyId).")
                return true
            }
        } catch {
            AppLogger.shared.log("Failed to remove key with ID: \(keyId). Error: \(error)", .error)
            return false
        }
        
        return false
    }
    
    
    /**
     Store metadata of an active MUSAP SSCD
     */
    public func addSscd(sscd: SscdInfo) throws {
        AppLogger.shared.log("Trying to add a new SSCD with type: \(sscd.getSscdType())")
        guard let sscdId = sscd.getSscdId() else {
            AppLogger.shared.log("Failed to add a new SSCD. No SSCD ID")
            return
        }
        
        // Update SSCD id list with new SSCD ID
        var sscdIds = getSscdIds()
        if !sscdIds.contains(sscdId) {
            AppLogger.shared.log("Adding new SSCD ID: \(sscdId)")
            sscdIds.insert(sscdId)
        } else {
            // Dont add SSCD with same ID
            AppLogger.shared.log("SSCD with this ID (\(sscdId) already exists).", .warning)
            throw MusapError.sscdAlreadyExists
        }

        if let sscdJson = try? JSONEncoder().encode(sscd) {
            userDefaults.set(Array(sscdIds), forKey: MetadataStorage.SSCD_ID_SET)
            userDefaults.set(sscdJson, forKey: try makeStoreName(sscd: sscd)!)
        } else {
            AppLogger.shared.log("Failed to save new SSCD", .error)
        }
    }
    
    public func removeSscd(sscd: SscdInfo) -> Bool {
        AppLogger.shared.log("Trying to remove SSCD")
        guard let targetSscdId = sscd.getSscdId() else {
            AppLogger.shared.log("Could not find SSCD ID for SSCD removal")
            return false
        }
        
        let sscds = self.listActiveSscds()
        
        AppLogger.shared.log("Found \(sscds.count) active SSCDs")
        
        for s in sscds {
            if let currentSscdId = s.getSscdId() {
                if currentSscdId == targetSscdId {
                    // Remove SSCD JSON
                    UserDefaults.standard.removeObject(forKey: MetadataStorage.SSCD_JSON_PREFIX + targetSscdId)
                    
                    // Remove from SSCD ID SET
                    var sscdIdSet = self.getSscdIds()
                    sscdIdSet.remove(targetSscdId)
                    
                    AppLogger.shared.log("Successfully removed SSCD with ID: \(targetSscdId)")

                    // Save new set without the removed ID
                    userDefaults.set(Array(sscdIdSet), forKey: MetadataStorage.SSCD_ID_SET)
                    return true
                }
            } else {
                AppLogger.shared.log("Could not find SSCD ID for \(s.getSscdType()) while looping through SSCDs", .warning)
            }
        }
        
        AppLogger.shared.log("Deleting SSCD failed", .error)
        
        return false
    }

    /**
     List available active MUSAP SSCDs
     */
    public func listActiveSscds() -> [SscdInfo] {
        AppLogger.shared.log("Trying to list active SSCD's")
        let sscdIds = getSscdIds()
        var sscdList: [SscdInfo] = []
        
        for sscdId in sscdIds {
            if let sscdData = self.getSscdJson(sscdId: sscdId) {
                do {
                    let sscd = try JSONDecoder().decode(SscdInfo.self, from: sscdData)
                    sscdList.append(sscd)
                } catch {
                    AppLogger.shared.log("Failed to decode SSCD JSON: \(error)")
                }
            } else {
                AppLogger.shared.log("Missing SSCD metadata JSON for SSCD ID: \(sscdId)")
            }
        }
        
        AppLogger.shared.log("Found \(sscdList.count) active SSCD's")
        
        return sscdList
    }

    
    private func getKeyIds() -> Set<String> {
        // Retrieve the array from UserDefaults and convert it back to a set
        let keyNamesArray = userDefaults.array(forKey: MetadataStorage.KEY_ID_SET) as? [String] ?? []
        AppLogger.shared.log("Got key IDs: \(keyNamesArray)")
        return Set(keyNamesArray)
    }

    private func getSscdIds() -> Set<String> {
        AppLogger.shared.log("Trying to get SSCD ID's")
        
        if let sscdIdsArray = userDefaults.stringArray(forKey: MetadataStorage.SSCD_ID_SET) {
            AppLogger.shared.log("Found \(sscdIdsArray.count) SSCD ID's")
            return Set(sscdIdsArray)
        } else {
            AppLogger.shared.log("Found 0 SSCD ID's")
            return Set()
        }
    }
    
    /**
     Generates a string to target a specific key in storage by using a MUSAP Key
     */
    private func makeStoreName(key: MusapKey) throws -> String {
        guard let keyId = key.getKeyId() else {
            AppLogger.shared.log("Key had no key id, can't create store name.", .error)
            throw MusapError.unknownKey
        }
        return MetadataStorage.KEY_JSON_PREFIX + keyId
    }
    
    /**
     Generates a string to target a specific SSCD by using given SSCD Info
     */
    private func makeStoreName(sscd: SscdInfo) throws -> String? {
        guard let sscdId = sscd.getSscdId() else {
            AppLogger.shared.log("Can't create a store name, SSCD ID is nil", .error)
            throw MusapError.illegalArgument
        }
        return MetadataStorage.SSCD_JSON_PREFIX + sscdId
    }
    
    private func makeStoreName(keyId: String) -> String {
        return MetadataStorage.KEY_JSON_PREFIX + keyId
    }
    
    
    private func getKeyJson(keyId: String) -> String? {
        AppLogger.shared.log("Trying to get key JSON for keyid: \(keyId)")
        let keyStoreName = self.makeStoreName(keyId: keyId)
        
        guard let keyJson = userDefaults.data(forKey: keyStoreName) else {
            AppLogger.shared.log("Could not find data for \(keyStoreName)", .error)
            return nil
        }
        
        return String(decoding: keyJson, as: UTF8.self)
    }
    
    public func printAllData() {
        AppLogger.shared.log("Printing all data...", .debug)
        
        let keyIds = self.getKeyIds()
        AppLogger.shared.log("All key ID's: \(keyIds)")

        let sscdIds = getSscdIds()
        AppLogger.shared.log("All SSCD ID's: \(sscdIds)")

        // Iterate through each key name and print its JSON
        for keyId in keyIds {
            if let keyData = userDefaults.data(forKey: makeStoreName(keyId: keyId)) {
                AppLogger.shared.log("Data for key with id: \(keyId) - \(keyData.base64EncodedString())")
            }
        }

        // Iterate through each SSCD ID and print its JSON
        for sscdId in sscdIds {
            if let sscdData = userDefaults.data(forKey: makeStoreName(keyId: sscdId)) {
                AppLogger.shared.log("Data for SSCD with id: \(sscdId) - \(sscdData.base64EncodedString())")
            }
        }
    }
    
    public func getImportData() -> MusapImportData {
        let sscds = self.listActiveSscds()
        let keys  = self.listKeys()
        return MusapImportData(sscds: sscds, keys: keys)
    }
    
    public func addImportData(data: MusapImportData) throws {
        AppLogger.shared.log("Adding import data...", .debug)
        let activeSscds  = self.listActiveSscds()
        let enabledSscds = MusapClient.listEnabledSscds() ?? [MusapSscd]()
        let activeKeys   = self.listKeys()

        for sscd in data.sscds ?? [] {
            let alreadyExists = activeSscds.contains { $0.getSscdId() == sscd.getSscdId() }
            let isSscdTypeEnabled = enabledSscds.contains { $0.getSscdInfo()?.getSscdType() == sscd.getSscdType() }

            if alreadyExists || !isSscdTypeEnabled {
                AppLogger.shared.log("Import data had a SSCD that already exists - skipped", .warning)
                continue
            }
            try self.addSscd(sscd: sscd)
        }

        let uniqueKeys = Set(activeKeys.map { $0.getKeyUri() })
        
        for key in data.keys ?? [] {
            if uniqueKeys.contains(key.getKeyUri()) {
                continue
            }
            /*
            guard let sscd = key.getSscdImplementation()?.getSscdInfo() else {
                throw MusapError.unknownKey
            }
             */
            guard let sscd = key.getSscd() else {
                return
            }
            
            do {
                AppLogger.shared.log("Storing key to SSCD: \(String(describing: sscd.getSscdInfo()?.getSscdName()))")
                guard let sscdInfo = sscd.getSscdInfo() else {
                    throw MusapError.internalError
                }
                try self.addKey(key: key, sscd: sscdInfo)
            } catch {
                AppLogger.shared.log("Could not store key to SSCD: \(String(describing: sscd.getSscdInfo()?.getSscdName()))")
                throw MusapError.internalError
            }
        }
    }
    
    private func getSscdJson(sscdId: String) -> Data? {
        AppLogger.shared.log("Retrieving SSCD JSON as Data() with id: \(sscdId)")
        guard let sscdJson = UserDefaults.standard.data(forKey: MetadataStorage.SSCD_JSON_PREFIX + sscdId) else {
            AppLogger.shared.log("Could not find SSCD with id: \(sscdId). Returning nil.")
            return nil
        }
        
        AppLogger.shared.log("Found SSCD JSON data for SSCD id: \(sscdId)")
        return sscdJson
    }
    
    public func updateKeyMetaData(req: UpdateKeyReq) -> Bool {
        AppLogger.shared.log("Trying to update key metadata")
        
        let targetKey = req.getKey()
        guard let keyId = targetKey.getKeyId() else {
            AppLogger.shared.log("Can't update key metadata as keyId was nil", .error)
            return false
        }
        
        guard let keyJson = self.getKeyJson(keyId: keyId) else {
            AppLogger.shared.log("Failed to update key metadata", .error)
            return false
        }
        
        AppLogger.shared.log("Found key metadata: \(keyJson)", .debug)
        
        guard let keyJsonData = keyJson.data(using: .utf8) else {
            AppLogger.shared.log("Error decoding JSON to MusapKey, can't update metadata", .error)
            return false
        }
        
        AppLogger.shared.log("Trying to decode JSON to MusapKey")
        
        // JSON to Musapkey
        let decoder = JSONDecoder()
        guard let oldKey = try? decoder.decode(MusapKey.self, from: keyJsonData) else {
            AppLogger.shared.log("Error decoding JSON to MusapKey, can't update metadata")
            return false
        }
        
        if req.getAlias() != nil {
            AppLogger.shared.log("Setting alias as \(req.getAlias() ?? "")")
            oldKey.setKeyAlias(value: req.getAlias())
        }
        
        if req.getDid() != nil {
            AppLogger.shared.log("Setting DID as \(req.getDid() ?? "")")
            oldKey.setDid(value: req.getDid())
        }
        
        if req.getState() != nil {
            AppLogger.shared.log("Setting state as \(req.getState() ?? "")")
            oldKey.setState(value: req.getState())
        }
        
        if let attributes = req.getAttributes() {
            if req.getAttributes() != nil {
                for attr in attributes {
                    
                    if attr.value == nil {
                        oldKey.removeAttribute(nameToRemove: attr.name)
                    } else {
                        oldKey.addAttribute(attr: attr)
                    }
                    
                }
            }
        }
        
        guard let sscd = oldKey.getSscd()?.getSscdInfo() else {
            AppLogger.shared.log("Can't update key metadata, could not find SSCD the key belongs to", .error)
            return false
        }
        
        do {
            try self.addKey(key: oldKey, sscd: sscd)
        } catch {
            AppLogger.shared.log("Storign key failed: \(error)")
            return false
        }
        
        AppLogger.shared.log("Successfully updated key metadata")
        return true
    }
    
}
