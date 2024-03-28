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
    public let keyuri:    String?
    public let keyid:     String?
    public var attestationResult: KeyAttestationResult?
    
    public init(linkid: String?, signature: MusapSignature?, attestationResult: KeyAttestationResult? = nil) {
        self.linkid = linkid
        self.signature = (signature != nil) ? signature?.getB64Signature() : nil
        self.publickey = signature?.getKey()?.getPublicKey()?.getPEM()
        self.keyuri = nil
        self.keyid  = nil
        self.attestationResult = attestationResult
    }
    
    public init(key: MusapKey) {
        self.keyid = key.getKeyId()
        self.keyuri = key.getKeyUri()?.getUri()
        self.publickey = key.getPublicKey()?.getPEM()
        self.linkid = nil
        self.signature = nil
    }
    
    public func getBase64Encoded() -> String? {
        guard let jsonData = try? JSONEncoder().encode(self) else {
            return nil
        }
        return jsonData.base64EncodedString()
    }
    
}
