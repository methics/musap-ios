//
//  File.swift
//  
//
//  Created by Teemu Mänttäri on 26.3.2024.
//

import Foundation

public class NoKeyAttestation: KeyAttestationProtocol {

    public var keyAttestationType: String
    
    public init() {
        self.keyAttestationType = KeyAttestationType.NONE
    }
    
    public func getAttestationData(key: MusapKey) -> KeyAttestationResult {
        return KeyAttestationResult(attestationType: self.getAttestationType())
    }
    
    public func getAttestationType() -> String {
        return self.keyAttestationType
    }
    
    public func isAttetationSupported() -> Bool {
        return false
    }
    
    
    
    
}
