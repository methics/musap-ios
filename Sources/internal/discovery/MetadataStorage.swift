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
        guard let keyId = key.getKeyId() else {
            print("Key ID was nil, cant store key")
            throw MusapException.init(MusapError.missingParam)
        }
        
        print("storeKey debug MusapKey algo: \(String(describing: key.getAlgorithm()))")
        
        // Create the key-specific store name using the prefix and the key ID
        let storeName = makeStoreName(keyId: keyId)
        
        // Encode the key to JSON and store it using the store name
        do {
            let keyJson = try JSONEncoder().encode(key)
            userDefaults.set(keyJson, forKey: storeName) // Use storeName to save the key JSON
            print("Key stored with name: \(storeName)")
        } catch {
            print("Could not encode key to JSON: \(error)")
            throw MusapException(MusapError.internalError)
        }
        
        // Insert the key ID into the set of known key names and save it
        var newKeyIds = getKeyIds()
        newKeyIds.insert(keyId)
        userDefaults.set(Array(newKeyIds), forKey: MetadataStorage.KEY_ID_SET)
        
        userDefaults.synchronize()
        self.addSscd(sscd: sscd)
        print("Updated key ID's: \(newKeyIds)")
    }
    
    /**
     List available MUSAP keys
     */
    public func listKeys() -> [MusapKey] {
        let keyIds = getKeyIds()
        var keyList: [MusapKey] = []

        for keyId in keyIds {
            if let keyData = userDefaults.data(forKey: makeStoreName(keyId: keyId)),
               let key = try? JSONDecoder().decode(MusapKey.self, from: keyData) {
                keyList.append(key)
            } else {
                print("Missing key metadata JSON for key ID: \(keyId)")
            }
        }

        return keyList
    }
    
    public func listKeys(req: KeySearchReq) -> [MusapKey] {
        let keyIds = self.getKeyIds()
        var keyList = [MusapKey]()
        
        for keyId in keyIds {
            let keyJson = self.getKeyJson(keyId: keyId)
            if let jsonData = keyJson.data(using: .utf8) {
                let decoder = JSONDecoder()

                do {
                    let key = try decoder.decode(MusapKey.self, from: jsonData)
                    if (req.keyMatches(key: key)) {
                        keyList.append(key)
                    }
                } catch {
                    print("Error decoding JSON for keyID: \(keyId), error: \(error)")
                }
            }
        }
        return keyList
        
    }
    
    /**
     Remove key metadata from storage
     */
    public func removeKey(key: MusapKey) -> Bool {
        guard let keyId = key.getKeyId() else {
            print("Can't remove key. Key ID was nil")
            return false
        }
        
        var newKeyIds = getKeyIds()
        newKeyIds.remove(keyId)

        if let keyJson = try? JSONEncoder().encode(key) {
            userDefaults.set(newKeyIds, forKey: MetadataStorage.KEY_ID_SET)
            userDefaults.set(keyJson, forKey: makeStoreName(key: key))
            userDefaults.removeObject(forKey: makeStoreName(keyId: keyId))
            return true
        }
        return false
    }
    
    
    /**
     Store metadata of an active MUSAP SSCD
     */
    public func addSscd(sscd: SscdInfo) {
        guard let sscdId = sscd.getSscdId() else {
            return
        }
        
        // Update SSCD id list with new SSCD ID
        var sscdIds = getSscdIds()
        if !sscdIds.contains(sscdId) {
            print("adding sscdid \(sscdId) to set")
            sscdIds.insert(sscdId)
        }

        if let sscdJson = try? JSONEncoder().encode(sscd) {
            userDefaults.set(Array(sscdIds), forKey: MetadataStorage.SSCD_ID_SET)
            userDefaults.set(sscdJson, forKey: makeStoreName(sscd: sscd)!)
        } else {
            print("Adding SSCD failed")
        }
    }

    /**
     List available active MUSAP SSCDs
     */
    public func listActiveSscds() -> [SscdInfo] {
        let sscdIds = getSscdIds()
        var sscdList: [SscdInfo] = []
        
        for sscdId in sscdIds {
            print("Found sscdId: \(sscdId)")
            if let sscdData = self.getSscdJson(sscdId: sscdId) {
                do {
                    let sscd = try JSONDecoder().decode(SscdInfo.self, from: sscdData)
                    
                    print("Appending new SSCD to SSCD list: \(sscd.getSscdName())")
                    
                    sscdList.append(sscd)
                } catch {
                    print("Error decoding sscd JSON: \(error)")
                }
            } else {
                print("Missing SSCD metadata JSON for SSCD ID: \(sscdId)")
            }
        }

        return sscdList
    }

    
    private func getKeyIds() -> Set<String> {
        // Retrieve the array from UserDefaults and convert it back to a set
        let keyNamesArray = userDefaults.array(forKey: MetadataStorage.KEY_ID_SET) as? [String] ?? []
        return Set(keyNamesArray)
    }

    private func getSscdIds() -> Set<String> {
        print("Getting SSCD IDs")
        if let sscdIdsArray = userDefaults.stringArray(forKey: MetadataStorage.SSCD_ID_SET) {
            print("Found \(sscdIdsArray.count) sscd ids")
            print("SSCD ID(1): \(sscdIdsArray.first)")
            return Set(sscdIdsArray)
        } else {
            print("found 0 sscd IDs, returning empty Set")
            return Set()
        }
    }
    
    private func makeStoreName(key: MusapKey) -> String {
        guard let keyId = key.getKeyId() else {
            fatalError("Cannot create store name with no key id")
        }
        return MetadataStorage.KEY_JSON_PREFIX + keyId
    }
    
    private func makeStoreName(sscd: SscdInfo) -> String? {
        guard let sscdId = sscd.getSscdId() else {
            print("makeStoreName: no sscd id")
            return nil
        }
        return MetadataStorage.SSCD_JSON_PREFIX + sscdId
    }
    
    private func makeStoreName(keyId: String) -> String {
        return MetadataStorage.KEY_JSON_PREFIX + keyId
    }
    
    
    private func getKeyJson(keyId: String) -> String {
        return self.makeStoreName(keyId: keyId)
    }
    
    public func printAllData() {
        // Print all key names
        //let keyNames = getKeyNames()
        //print("All Key Names: \(keyNames)")
        
        let keyIds = self.getKeyIds()
        print("All key IDs: \(keyIds)")

        // Print all SSCD IDs
        let sscdIds = getSscdIds()
        print("All SSCD IDs: \(sscdIds)")

        // Iterate through each key name and print its JSON
        for keyId in keyIds {
            if let keyData = userDefaults.data(forKey: makeStoreName(keyId: keyId)) {
                print("Data for key '\(keyId)': \(keyData)")
            }
        }

        // Iterate through each SSCD ID and print its JSON
        for sscdId in sscdIds {
            if let sscdData = userDefaults.data(forKey: makeStoreName(keyId: sscdId)) {
                print("Data for SSCD ID '\(sscdId)': \(sscdData)")
            }
        }
    }
    
    public func getImportData() -> MusapImportData {
        let sscds = self.listActiveSscds()
        let keys  = self.listKeys()
        return MusapImportData(sscds: sscds, keys: keys)
    }
    
    public func addImportData(data: MusapImportData) throws {
        let activeSscds  = self.listActiveSscds()
        let enabledSscds = MusapClient.listEnabledSscds() ?? [MusapSscd]()
        let activeKeys   = self.listKeys()

        for sscd in data.sscds ?? [] {
            let alreadyExists = activeSscds.contains { $0.getSscdId() == sscd.getSscdId() }
            let isSscdTypeEnabled = enabledSscds.contains { $0.getSscdInfo()?.getSscdType() == sscd.getSscdType() }

            if alreadyExists || !isSscdTypeEnabled {
                continue
            }
            self.addSscd(sscd: sscd)
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
                print("Storing key to \(String(describing: sscd.getSscdInfo()?.getSscdName()))")
                guard let sscdInfo = sscd.getSscdInfo() else {
                    throw MusapError.internalError
                }
                try self.addKey(key: key, sscd: sscdInfo)
            } catch {
                print("Could not store key to \(String(describing: sscd.getSscdInfo()?.getSscdName()))")
                throw MusapError.internalError
            }
        }
    }
    
    private func getSscdJson(sscdId: String) -> Data? {
        guard let sscdJson = UserDefaults.standard.data(forKey: MetadataStorage.SSCD_JSON_PREFIX + sscdId) else {
            print("Could not find SSCD JSON for \(MetadataStorage.SSCD_JSON_PREFIX + sscdId)")
            return nil
        }
        return sscdJson
    }
    
    public func updateKeyMetaData(req: UpdateKeyReq) -> Bool {
        let targetKey = req.getKey()
        
        guard let keyId = targetKey.getKeyId() else {
            print("Can't update key metadata, keyid was nil")
            return false
        }
        
        //TODO: keyname: keyId?
        let keyJson = self.getKeyJson(keyId: keyId)
        guard let keyJsonData = keyJson.data(using: .utf8) else {
            print("Error decoding JSON to MusapKey, can't update metadata")
            return false
        }
        
        // JSON to Musapkey
        let decoder = JSONDecoder()
        guard let oldKey = try? decoder.decode(MusapKey.self, from: keyJsonData) else {
            print("Error: Decoding JSON to MusapKey failed")
            return false
        }
        
        if req.getAlias() != nil {
            oldKey.setKeyAlias(value: req.getAlias())
        }
                
        if req.getDid() != nil {
            oldKey.setDid(value: req.getDid())
        }
         
        if req.getState() != nil {
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
        
        guard let sscd = oldKey.getSscdInfo() else {
            print("Can't update key, could nto find SSCD where it belongs")
            return false
        }
        
        do {
            try self.addKey(key: oldKey, sscd: sscd)
        } catch {
            return false
        }
        
        return true
        
    }
    
}
