//
//  BindKeyTask.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 15.11.2023.
//

import Foundation

public class BindKeyTask {
    
    typealias CompletionHandler = (Result<MusapKey, MusapError>) -> Void
    
    func bindKey(req: KeyBindReq, sscd: MusapSscd) async throws -> MusapKey {
        do {
            let key = try sscd.bindKey(req: req)
            AppLogger.shared.log("BindKeyTask got MUSAP key")
            
            let storage = MetadataStorage()
            
            guard let activeSscd = sscd.getSscdInfo() else {
                AppLogger.shared.log("Binding key failed since we have no SSCD info")
                throw MusapError.internalError
            }
                        
            guard let sscdId = sscd.getSscdId() else {
                AppLogger.shared.log("Binding key failed since we have no SSCD ID")
                throw MusapError.internalError
            }
            
            AppLogger.shared.log("SSCD ID: \(sscdId)")
            
            activeSscd.setSscdId(sscdId: sscdId)
            key.setSscdId(value: sscdId)
            
            try storage.addKey(key: key, sscd: activeSscd)
            return key
        } catch {
            throw MusapError.internalError
        }
        
        
    }
    
}
