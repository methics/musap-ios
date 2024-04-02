//
//  File.swift
//  
//
//  Created by Teemu Mänttäri on 2.4.2024.
//

import Foundation

public protocol TransportEncryption {
    
    func encrypt(message: String)  -> EncryptedPayload
    func encrypt(message: String, iv: String) -> EncryptedPayload
    func decrypt(message: Data, iv: String) -> String
}
