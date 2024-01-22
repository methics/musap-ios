//
//  SignatureAttribute.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 24.11.2023.
//

import Foundation

public class SignatureAttribute: Decodable {
    
    public let name: String
    public let value: String
    
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    
}
