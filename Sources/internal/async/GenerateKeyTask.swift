//
//  GenerateKeyTask.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 6.11.2023.
//

import Foundation

public class GenerateKeyTask {

    typealias CompletionHandler = (Result<MusapKey, MusapError>) -> Void

    func generateKeyAsync(sscd: any MusapSscdProtocol, req: KeyGenReq, completion: @escaping CompletionHandler) async throws -> MusapKey {
        do {
            let key = try await withCheckedThrowingContinuation { continuation in
                do {
                    let generatedKey = try sscd.generateKey(req: req)
                    let activeSscd   = sscd.getSscdInfo()
                    guard let sscdId = sscd.getSscdInfo().getSscdId() else {
                        print("Could not get SSCD id")
                        throw MusapError.internalError
                    }
                    
                    activeSscd.setSscdId(sscdId: sscdId)
                    generatedKey.setSscdId(value: sscdId)
                    
                    let storage = MetadataStorage()
                    try storage.addKey(key: generatedKey, sscd: activeSscd)

                    continuation.resume(returning: generatedKey)
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            return key
        } catch {
            completion(.failure(MusapError.internalError))
            throw MusapError.internalError
        }
    }
}
