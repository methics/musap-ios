//
//  File.swift
//  
//
//  Created by Teemu Mänttäri on 27.3.2024.
//

import Foundation

public class CertificateKeyAttestation: KeyAttestationProtocol {
    
    public var keyAttestationType: String
    
    public init(keyAttestationType: String) {
        self.keyAttestationType = keyAttestationType
    }
    
    public func getAttestationData(key: MusapKey) -> KeyAttestationResult {
        guard let chain = key.getCertificateChain() else {
            return KeyAttestationResult(attestationStatus: KeyAttestationResult.AttestationStatus.INVALID)
        }
        
        var result = KeyAttestationResult(attestationType: self.getAttestationType())
        result.setCertificateChain(certificateChain: chain)
        
        guard let certificate = key.getCertificate() else {
            // there should always be certificate if there is a chain
            return result
        }
        result.setCertificate(certificate: certificate)
        
        return result
    }
    
    public func getAttestationType() -> String {
        return self.keyAttestationType
    }
    
    public func isAttetationSupported() -> Bool {
        return true
    }
    
    
}
