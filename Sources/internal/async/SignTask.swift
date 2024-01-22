//
//  SignTask.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.11.2023.
//

import Foundation

class SignTask {

    func sign(req: SignatureReq) async throws -> MusapSignature {
        let sscd = req.getKey().getSscdImplementation()
        guard let sscd = sscd else {
            print("Could not find SSCD implementation")
            throw MusapError.internalError
        }
        
        return try sscd.sign(req: req)
    }
    
}
