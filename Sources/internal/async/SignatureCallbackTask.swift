//
//  SignatureCallbackTask.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 15.1.2024.
//

import Foundation


public class SignatureCallbackTask {

    func runTask(link: MusapLink, signature: MusapSignature, txnId: String) throws {
        do {
            try link.sendSignatureCallback(signature: signature, transId: txnId)
        } catch {
            print("SignatureCallbackTask.runTask(): \(error)")
            throw MusapError.internalError
        }
    }
    
}
