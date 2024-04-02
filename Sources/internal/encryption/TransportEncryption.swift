//
//  TransportEncryption.swift
//
//
//  Created by Teemu Mänttäri on 2.4.2024.
//

import Foundation

public protocol TransportEncryption {
    
    func encrypt(message: String)  -> PayloadHolder
    func encrypt(message: String, iv: String) -> PayloadHolder
    func decrypt(message: Data, iv: String) -> String
    
}
