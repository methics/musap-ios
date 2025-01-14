//
//  SignTask.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.11.2023.
//

import Foundation

public class SignTask {

    func sign(req: SignatureReq) async throws -> MusapSignature {
        let sscd = req.getKey().getSscd()
        guard let sscd = sscd else {
            AppLogger.shared.log("Sign task failed since we could not find SSCD implementation")
            throw MusapError.internalError
        }
        
        return try sscd.sign(req: req)
    }
    
}
