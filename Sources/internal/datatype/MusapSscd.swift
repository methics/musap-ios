//
//  MusapSscd.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public class MusapSscd: Identifiable {
    
    public static let SETTING_SSCDID = "id"
    
    private var impl: any MusapSscdProtocol
    
    public init(impl: any MusapSscdProtocol) {
        self.impl = impl
    }
    
    public func getSscdInfo() -> SscdInfo? {
        guard let sscdId = self.getSscdId() else {
            print("Could not get Sscd ID")
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
        var keys = [MusapKey]()
        for key in MusapClient.listKeys() {
            print("Found key: \(key.getKeyAlias())")
            
            if key.getSscdId() == nil {
                print("key sscd id was nil")
            } else {
                print("Key sscd Id was not nil: \(String(describing: key.getSscdId()))")
                
                print(" self.getSscdId: \(String(describing: self.getSscdId()))")
            }
            
            if key.getSscdId() == nil { continue }
            if key.getSscdId() == self.getSscdId() {
                print("Appending key to key lis in listKeys()")
                keys.append(key)
            }
        }
        return keys
    }
    
    public func getKey(keyId: String) -> MusapKey? {
        for key in self.listKeys() {
            if keyId == key.getKeyId() {
                return key
            }
        }
        return nil
    }
    
    public func removeKey(key: MusapKey) -> Bool {
        for k in self.listKeys() {
            if k.getKeyId() == key.getKeyId() {
               return MusapClient.removeKey(musapKey: key)
            }
        }
        
        return false
    }
    
    public func removeKeys() -> Bool {
        var _ = [MusapKey]()
        var removed = false
        
        for key in self.listKeys() {
            let _ = MusapClient.removeKey(musapKey: key)
            removed = true
        }
        
        return removed
    }
    
    public func getSettings() -> SscdSettings {
        return self.impl.getSettings()
    }
    
    public func getSetting(name: String) -> String? {
        return self.getSettings().getSetting(forKey: name)
    }
    
}
