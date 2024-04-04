//
//  File.swift
//  
//
//  Created by Teemu Mänttäri on 26.3.2024.
//

import Foundation

public protocol KeyAttestationProtocol {
    var keyAttestationType: String { get }
    
    func getAttestationData(key: MusapKey) -> KeyAttestationResult
    func getAttestationType() -> String
    func isAttetationSupported() -> Bool
}

extension KeyAttestationProtocol {
    func isAttestationSupported() -> Bool {
        return true
    }
}
