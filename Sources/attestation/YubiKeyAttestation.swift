//
//  File.swift
//  
//
//  Created by Teemu Mänttäri on 27.3.2024.
//

import Foundation
import Security

public class YubiKeyAttestation: KeyAttestationProtocol {
    
    public var keyAttestationType: String
    public var certificates: [String: Data]?
    
    public init(keyAttestationType: String, certificates: [String : Data]?) {
        self.keyAttestationType = keyAttestationType
        self.certificates = certificates
    }
    
    public func getAttestationData(key: MusapKey) -> KeyAttestationResult {
        var result = KeyAttestationResult(attestationStatus: KeyAttestationResult.AttestationStatus.UNDETERMINED)
        
        guard let keyId = key.getKeyId(),
              let cert  = self.getCertificate(keyId: keyId)
        else {
            // Invalid attestation
            result.setAttestationStatus(attestationStatus: KeyAttestationResult.AttestationStatus.INVALID)
            return result
        }
        
        result.setCertificate(certificate: cert)
        return result
    }
    
    public func getAttestationType() -> String {
        return self.keyAttestationType
    }
    
    public func isAttetationSupported() -> Bool {
        return true
    }
    
    public func getCertificate(keyId: String) -> MusapCertificate? {
        guard let certificates = self.certificates else {
            return nil
        }
        
        if let certificateData = certificates[keyId] {
            if let cfData = CFDataCreate(nil, [UInt8](certificateData), certificateData.count) {
                guard let certificate = SecCertificateCreateWithData(nil, cfData) else {
                    // Failed to create SecCertificate
                    print("Failed to create SecCertificate")
                    return nil
                }
                return MusapCertificate(cert: certificate)
            } else {
                // CFDataCreate failed
                return nil
            }
        }
        // certificate not found
        return nil
    }
    
}
