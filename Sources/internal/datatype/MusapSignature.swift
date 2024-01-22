//
//  MusapSignature.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 7.11.2023.
//

import Foundation

public class MusapSignature {
    
    private let rawSignature: Data
    private let key:          MusapKey?
    private let algorithm:    SignatureAlgorithm?
    private let format:       SignatureFormat?
    

    /// Create a new MUSAP signture object
    init(rawSignature: Data, key: MusapKey, algorithm: SignatureAlgorithm, format: SignatureFormat) {
        self.rawSignature = rawSignature
        self.key          = key
        self.algorithm    = algorithm
        self.format       = format
    }
    
    /// Create a new raw signature without any meta-data
    init(rawSignature: Data) {
        self.rawSignature = rawSignature
        self.key          = nil
        self.algorithm    = nil
        self.format       = nil
    }
    
    init(rawSignature: Data, key: MusapKey) {
        self.rawSignature = rawSignature
        self.key          = key
        self.algorithm    = nil
        self.format       = nil
    }
    
    public func getSignatureAlgorithm() -> SignatureAlgorithm? {
        return self.algorithm
    }
    
    public func getSignatureFormat() -> SignatureFormat? {
        return self.format
    }
    
    public func getKey() -> MusapKey? {
        return self.key
    }
    
    public func getRawSignature() -> Data {
        return self.rawSignature
    }
    
    public func getB64Signature() -> String {
        return self.rawSignature.base64EncodedString()
    }
    
    public func getPublicKey() -> PublicKey? {
        guard let key = self.getKey() else {
            return nil
        }
        return self.key?.getPublicKey()
    }
    
    
}
