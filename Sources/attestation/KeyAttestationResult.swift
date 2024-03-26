//
//  File.swift
//  
//
//  Created by Teemu Mänttäri on 26.3.2024.
//

import Foundation

public class KeyAttestationResult {
    
    private let attestationType: String
    private let attestationSignature: Data?
    private let certificate: MusapCertificate?
    private let certificateChain: [MusapCertificate]?
    private let attestationStatus: AttestationStatus?
    
    public init(
        attestationType: String,
        attestationSignature: Data,
        certificate: MusapCertificate,
        certificateChain: [MusapCertificate],
        attestationStatus: AttestationStatus
    ) {
        self.attestationType = attestationType
        self.attestationSignature = attestationSignature
        self.certificate = certificate
        self.certificateChain = certificateChain
        self.attestationStatus = attestationStatus
    }
    
    // AttestationType NONE init
    public init(attestationType: String) {
        self.attestationType = attestationType
        self.attestationSignature = nil
        self.certificate = nil
        self.certificateChain = nil
        self.attestationStatus = nil
    }
    
    public func getAttestationStatus() -> AttestationStatus? {
        return self.attestationStatus
    }
    
    public func getAttestationType() -> String {
        return self.attestationType
    }
    
    public func getSignature() -> Data? {
        return self.attestationSignature
    }
    
    public func toJson() {
        //TODO:
    }
    
    public enum AttestationStatus {
        case INVALID
        case UNDETERMINED
    }
    
}
