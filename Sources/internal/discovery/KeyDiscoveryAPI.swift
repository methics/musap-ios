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
        let enabledSscds = KeyDiscoveryAPI.enabledSscds
        var result = [any MusapSscdProtocol]()
        
        for sscd in enabledSscds {
            if req.matches(sscd: sscd.getSscdInfo()) {
                result.append(sscd)
            }
        }
        
        return result
    }
    
    public func listActiveSscds() -> [SscdInfo] {
        print("Listing active SSCDs")
        return storage.listActiveSscds()
    }
    
    public func enableSscd(_ sscd: any MusapSscdProtocol) -> Void {
        let isAlreadyEnabled = KeyDiscoveryAPI.enabledSscds.contains { existingSscd in
            existingSscd.getSscdInfo().getSscdName() == sscd.getSscdInfo().getSscdName()
        }
        // Dont add duplicate
        if isAlreadyEnabled {
            return
        }
        
        KeyDiscoveryAPI.enabledSscds.append(sscd)
    }
    
    public func listKeys(req: KeySearchReq) -> [MusapKey] {
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
