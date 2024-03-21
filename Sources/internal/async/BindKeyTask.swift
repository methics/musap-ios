//
//  BindKeyTask.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 15.11.2023.
//

import Foundation

public class BindKeyTask {
    
    typealias CompletionHandler = (Result<MusapKey, MusapError>) -> Void
    
    func bindKey(req: KeyBindReq, sscd: any MusapSscdProtocol) async throws -> MusapKey {
        do {
            print("BindKeyTask.bindKey() - Trying to sscd.bindKey()")
            let key = try sscd.bindKey(req: req)
            print("BindKeyTask got MUSAP key")
            
            let storage = MetadataStorage()
            let activeSscd = sscd.getSscdInfo()
            let sscdId = sscd.generateSscdId(key: key)
            
            activeSscd.setSscdId(sscdId: sscdId)
            key.setSscdId(value: sscdId)
    
            
            try storage.addKey(key: key, sscd: activeSscd)
            return key
        } catch {
            throw MusapError.internalError
        }
        
        
    }
    
}
