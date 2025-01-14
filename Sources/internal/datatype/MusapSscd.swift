//
//  MusapSscd.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public class MusapSscd: Identifiable {
    
    public static let SETTING_SSCDID = "id"
    
    public var impl: any MusapSscdProtocol
    
    public init(impl: any MusapSscdProtocol) {
        self.impl = impl
    }
    
    public func getSscdInfo() -> SscdInfo? {
        guard let sscdId = self.getSscdId() else {
            AppLogger.shared.log("Could not get SSCD ID", .error)
            return self.impl.getSscdInfo()
        }
        let info = self.impl.getSscdInfo()
        info.setSscdId(sscdId: sscdId)
        return info
    }
    
    public func getSscdId() -> String? {
        return self.impl.getSetting(forKey: MusapSscd.SETTING_SSCDID)
    }
    
    public func sign(req: SignatureReq) throws -> MusapSignature {
        return try self.impl.sign(req: req)
    }
    
    public func bindKey(req: KeyBindReq) throws -> MusapKey {
        return try self.impl.bindKey(req: req)
    }
    
    public func generateKey(req: KeyGenReq) throws -> MusapKey {
        return try self.impl.generateKey(req: req)
    }
    
    public func listKeys() -> [MusapKey]{
        AppLogger.shared.log("Trying to list keys...")
        
        var result = [MusapKey]()
        
        for key in MusapClient.listKeys() {
            AppLogger.shared.log("Found key: \(key.getKeyAlias() ?? "(no alias)")")
            
            if key.getSscdId() == nil {
                AppLogger.shared.log("Key had no SSCD ID, continuing...", .warning)
                continue
            }
            
            if key.getSscdId() == self.getSscdId() {
                AppLogger.shared.log("Found a key belonging to this SSCD, adding to result...")
                result.append(key)
            }
        }
        return result
    }
    
    public func getKey(keyId: String) -> MusapKey? {
        AppLogger.shared.log("Getting key with key ID: \(keyId)")
        for key in self.listKeys() {
            if keyId == key.getKeyId() {
                AppLogger.shared.log("Found key with alias: \(key.getKeyAlias() ?? "(null alias)")")
                return key
            }
        }
        AppLogger.shared.log("No key found", .warning)
        return nil
    }
    
    public func removeKey(key: MusapKey) -> Bool {
        AppLogger.shared.log("Trying to remove a key with key id: \(key.getKeyId() ?? "(null)")")
        for k in self.listKeys() {
            if k.getKeyId() == key.getKeyId() {
               return MusapClient.removeKey(musapKey: key)
            }
        }
        
        AppLogger.shared.log("Unable to find key to remove", .warning)
        return false
    }
    
    
    /// Removes keys belonging to this SSCD
    public func removeKeys() -> Bool {
        let savedKeys = self.listKeys()
        AppLogger.shared.log("Trying to remove all keys, current key count: \(savedKeys.count)")
        
        var _ = [MusapKey]()
        var removed = false
        
        for key in savedKeys {
            let _ = MusapClient.removeKey(musapKey: key)
            removed = true
        }
        
        AppLogger.shared.log("Finished removing keys. Current count: \(self.listKeys().count)")
        return removed
    }
    
    public func getSettings() -> SscdSettings {
        return self.impl.getSettings()
    }
    
    public func getSetting(name: String) -> String? {
        return self.getSettings().getSetting(forKey: name)
    }
    
    public func getKeyAttestation() -> KeyAttestationProtocol {
        return self.impl.getKeyAttestation()
    }
    
}
