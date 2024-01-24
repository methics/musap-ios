//
//  SignatureReq.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public class SignatureReq {
    
    public let key:         MusapKey
    public let data:        Data
    public let algorithm:   SignatureAlgorithm
    public let format:      SignatureFormat
    public let displayText: String
    public let attributes:  [SignatureAttribute]
    
    private let transId: String? = "" //TODO: ?
    
    public init(key: MusapKey, data: Data, algorithm: SignatureAlgorithm, format: SignatureFormat, displayText: String, attributes: [SignatureAttribute]) {
        self.key         = key
        self.data        = data
        self.algorithm   = algorithm
        self.format      = format
        self.displayText = displayText
        self.attributes  = attributes
    }
    
    public func getKey() -> MusapKey {
        return self.key
    }
    
    public func getData() -> Data {
        return self.data
    }
    
    public func getAlgorithm() -> SignatureAlgorithm {
        return self.algorithm
    }
    
    public func getFormat() -> SignatureFormat {
        return self.format
    }
    
    public func getAttributes() -> [SignatureAttribute] {
        return self.attributes
    }
    
    public func getAttribute(name: String) -> String? {
        for attribute in self.getAttributes() {
            if name == attribute.name {
                return attribute.value
            }
        }
        
        return nil
    }
    
    public func getDisplayText() -> String {
        return self.displayText
    }
    
    public func getTransId() -> String? {
        return self.transId
    }
    
}
