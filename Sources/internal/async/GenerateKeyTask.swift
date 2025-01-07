//
//  GenerateKeyTask.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 6.11.2023.
//

import Foundation

public class GenerateKeyTask {

    typealias CompletionHandler = (Result<MusapKey, MusapError>) -> Void

    func generateKeyAsync(sscd: MusapSscd, req: KeyGenReq, completion: @escaping CompletionHandler) async throws -> MusapKey {
        do {
            AppLogger.shared.log("Trying to generate a key (async)")
            
            let generatedKey = try sscd.generateKey(req: req)
            
            guard let activeSscd = sscd.getSscdInfo() else {
                AppLogger.shared.log("Failed to generate a key (async) - could not get SscdInfo")
                throw MusapError.illegalArgument
            }
            
            guard let sscdId = sscd.getSscdId() else {
                AppLogger.shared.log("Failed to generate a key (async) - could not get SSCD ID")
                throw MusapError.internalError
            }
            
            generatedKey.setSscdId(value: sscdId)
            
            let storage = MetadataStorage()
            try storage.addKey(key: generatedKey, sscd: activeSscd)
            
            completion(.success(generatedKey))
            
            return generatedKey
        } catch {
            completion(.failure(MusapError.internalError))
            throw MusapError.internalError
        }
    }
}
