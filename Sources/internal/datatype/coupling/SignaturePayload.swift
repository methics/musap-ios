//
//  SignaturePayload.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.1.2024.
//

import Foundation

public class SignaturePayload: Decodable {
    
    public var data: String
    public var display = "Sign with MUSAP"
    public var format: String? = "RAW"
    public var scheme: String?
    public var hashAlgo: String? = "SHA-256" //TODO: Swiftify?
    public let linkid: String
    public var key: KeyIdentifier? = nil
    public var attributes: [SignatureAttribute]?
    public var mode: String? = nil
    
    
    init(data:  String,
         format: String? = "RAW",
         scheme: String?,
         linkid: String,
         key: KeyIdentifier?,
         attributes: [SignatureAttribute]?,
         hashAlgo: String? = "SHA-256",
         mode: String?
    )
    {
        self.data = data
        self.format = format
        self.scheme = scheme
        self.linkid = linkid
        self.key = key
        self.attributes = attributes
        self.hashAlgo = hashAlgo ?? "SHA-256"
        self.mode = mode
    }
    
    public func toSignatureReq(key: MusapKey) -> SignatureReq? {
        /*
        guard let format = self.format else {
            print("toSignatureReq: format was nil")
            return nil
        }
         */
        let format = self.format ?? "RAW"
        let signatureFormat = SignatureFormat.fromString(format: format)
        let keyAlgo = key.getAlgorithm()
        
        var signAlgo: SignatureAlgorithm?
        if (self.scheme == nil) {
            signAlgo = keyAlgo?.toSignatureAlgorithm()
        } else {
            if let keyAlgorithm = key.getAlgorithm() {
                if keyAlgorithm.isEc() {
                    signAlgo = SignatureAlgorithm(algorithm: .ecdsaSignatureMessageX962SHA384)
                } else {
                    signAlgo = SignatureAlgorithm(algorithm: .rsaSignatureMessagePKCS1v15SHA256)
                }
            }
        }
        
        guard let dataBase64 = data.data(using: .utf8)?.base64EncodedData() else {
            print("Cant turn base64 to data")
            return nil
        }
        
        let sigReq = SignatureReq(key: key,
                                  data: dataBase64,
                                  algorithm: signAlgo ?? SignatureAlgorithm(algorithm: SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256),
                                  format: signatureFormat,
                                  displayText: self.display,
                                  attributes: self.attributes ?? [SignatureAttribute]()
        )
        
        return sigReq
    }
    
    //TODO: finish
    public func toKeygenReq() -> KeyGenReq? {
        let req = KeyGenReq(keyAlias: self.key?.keyAlias ?? "musap_key", role: "user")
        return req
    }

    
    public class KeyIdentifier: Decodable {
        public let keyId: String
        public let keyAlias: String
        public let publicKeyHash: String
        
        init(keyId: String, keyAlias: String, publicKeyHash: String) {
            self.keyId = keyId
            self.keyAlias = keyAlias
            self.publicKeyHash = publicKeyHash
        }
    }
    
}
