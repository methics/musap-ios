//
//  MusapCertificate.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 7.11.2023.
//

import Foundation

public class MusapCertificate: Codable {
    
    private let subject: String
    private let certificate: Data
    private let publicKey: PublicKey
    
    public init(subject: String, certificate: Data, publicKey: PublicKey) {
        self.subject = subject
        self.certificate = certificate
        self.publicKey = publicKey
    }
    
    public init?(cert: SecCertificate) {
        if let subjectCFString = SecCertificateCopySubjectSummary(cert) as String? {
            self.subject = subjectCFString
        } else {
            return nil
        }

        self.certificate = SecCertificateCopyData(cert) as Data

        guard let publicKeyRef = SecCertificateCopyKey(cert) else {
            return nil
        }

        var error: Unmanaged<CFError>?
        if let publicKeyData = SecKeyCopyExternalRepresentation(publicKeyRef, &error) as Data? {
            self.publicKey = PublicKey(publicKey: publicKeyData)
        } else {
            AppLogger.shared.log("Error extracting public key: \(error?.takeRetainedValue() as Error?)")
            return nil
        }
    }
    
    public func getSubject() -> String {
        return self.subject
    }
    
    public func getCertificate() -> Data {
        return self.certificate
    }
    
    public func getPublicKey() -> PublicKey {
        return self.publicKey
    }

    
    private func dataToSecCert()  -> SecCertificate? {        
        if let cfData = CFDataCreate(nil, [UInt8](self.certificate), self.certificate.count) {
            return SecCertificateCreateWithData(nil, cfData)
        }
        
        return nil
    }
    
    enum CertificateError: Error {
        case parsingFailed
    }
    
    
}
