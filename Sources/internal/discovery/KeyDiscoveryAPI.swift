//
//  KeyDiscoveryAPI.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.11.2023.
//

import Foundation

public class KeyDiscoveryAPI {
        
    private static var enabledSscds: [any MusapSscdProtocol] = [any MusapSscdProtocol]()
    private var storage: MetadataStorage
    
    public init(storage: MetadataStorage) {
        self.storage = storage
        KeyDiscoveryAPI.enabledSscds = KeyDiscoveryAPI.enabledSscds
    }
    
    public func listEnabledSscds() -> [any MusapSscdProtocol] {
        return KeyDiscoveryAPI.enabledSscds
    }
    
    public func listMatchingSscds(req: SscdSearchReq) -> [any MusapSscdProtocol] {
        return KeyDiscoveryAPI.enabledSscds
    }
    
    public func listActiveSscds() -> [MusapSscd] {
        print("Listing active SSCDs")
        return storage.listActiveSscds()
    }
    
    public func enableSscd(_ sscd: any MusapSscdProtocol) -> Void {
        let isAlreadyEnabled = KeyDiscoveryAPI.enabledSscds.contains { existingSscd in
            existingSscd.getSscdInfo().sscdName == sscd.getSscdInfo().sscdName
        }
        // Dont add duplicate
        if isAlreadyEnabled {
            return
        }
        
        KeyDiscoveryAPI.enabledSscds.append(sscd)
    }
    
    public func findKey(req: KeySearchReq) -> [MusapKey] {
        let keys = self.listKeys()
        
        var matchingKeys = [MusapKey]()
        for key in keys {
            if req.keyMatches(key: key) {
                matchingKeys.append(key)
            }
        }
        
        return matchingKeys
    }
    
    public func listKeys() -> [MusapKey] {
        return self.storage.listKeys()
    }
    
    public func removeKey(key: MusapKey) -> Bool {
        return self.storage.removeKey(key: key)
    }
    
}
