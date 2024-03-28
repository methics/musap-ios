//
//  File.swift
//  
//
//  Created by Teemu Mänttäri on 26.3.2024.
//

import Foundation

public class KeyAttestationResult: Encodable {
    
    private var attestationType: String?
    private var attestationSignature: Data?
    private var certificate: MusapCertificate?
    private var certificateChain: [MusapCertificate]?
    private var attestationStatus: AttestationStatus?
    
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
    
    public init(attestationStatus: AttestationStatus) {
        self.attestationType = nil
        self.attestationSignature = nil
        self.certificate = nil
        self.certificateChain = nil
        self.attestationStatus = attestationStatus
    }
    
    
    public func getAttestationStatus() -> AttestationStatus? {
        return self.attestationStatus
    }
    
    public func setAttestationStatus(attestationStatus: AttestationStatus) -> Void {
        self.attestationStatus = attestationStatus
    }
    
    public func setCertificate(certificate: MusapCertificate) -> Void {
        self.certificate = certificate
    }
    
    public func getCertificate() -> MusapCertificate? {
        return self.certificate
    }
    
    public func setCertificateChain(certificateChain: [MusapCertificate]) -> Void {
        self.certificateChain = certificateChain
    }
    
    public func getAttestationType() -> String? {
        return self.attestationType
    }
    
    public func getSignature() -> Data? {
        return self.attestationSignature
    }
    
    public func toJson() {
        //TODO:
    }
    
    public enum AttestationStatus: Encodable {
        case INVALID
        case UNDETERMINED
    }
    
}
