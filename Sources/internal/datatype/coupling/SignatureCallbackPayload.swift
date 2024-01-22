//
//  SignatureCallbackPayload.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 15.1.2024.
//

import Foundation

public class SignatureCallbackPayload: Encodable {
    
    public let linkid:    String?
    public let publickey: String?
    public let signature: String?
    
    init(linkid: String?, signature: MusapSignature?) {
        self.linkid = linkid
        self.signature = (signature != nil) ? signature?.getB64Signature() : nil
        self.publickey = signature?.getKey()?.getPublicKey()?.getPEM()
    }
    
    public func getBase64Encoded() -> String? {
        guard let jsonData = try? JSONEncoder().encode(self) else {
            return nil
        }
        return jsonData.base64EncodedString()
    }
    
}
