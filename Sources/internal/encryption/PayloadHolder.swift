//
//  File.swift
//  
//
//  Created by Teemu Mänttäri on 2.4.2024.
//

import Foundation

public class PayloadHolder {
    
    public let payload: String
    public let iv: String?
    
    public init(payload: String, iv: String?) {
        self.payload = payload
        self.iv = iv
    }
    
    public func getIv() -> String? {
        return self.iv
    }
    
    public func getPayload() -> String {
        return self.payload
    }
    
}
