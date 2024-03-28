//
//  BindKeyTask.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 15.11.2023.
//

import Foundation

public class BindKeyTask {
    
    typealias CompletionHandler = (Result<MusapKey, MusapError>) -> Void
    
    //TODO: Test this thorougly
    func bindKey(req: KeyBindReq, sscd: MusapSscd) async throws -> MusapKey {
        do {
            let key = try sscd.bindKey(req: req)
            print("BindKeyTask got MUSAP key")
            
            let storage = MetadataStorage()
            
            guard let activeSscd = sscd.getSscdInfo() else {
                print("BindKeyTask: Could not get SSCD Info")
                throw MusapError.internalError
            }
            
            print("sscd id: \(String(describing: activeSscd.getSscdId()))")
            
            guard let sscdId = sscd.getSscdId() else {
                print("BindKeyTask: Could not get SSCD ID")
                throw MusapError.internalError
            }
            
            activeSscd.setSscdId(sscdId: sscdId)
            key.setSscdId(value: sscdId)
            
            try storage.addKey(key: key, sscd: activeSscd)
            return key
        } catch {
            throw MusapError.internalError
        }
        
        
    }
    
}
