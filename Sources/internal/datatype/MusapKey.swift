//
//  MusapKey.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public class MusapKey: Codable, Identifiable {
    
    public var id = UUID() // For identifiable
    private var keyAlias: String?
    private var keyType: String?
    private var keyId: String?
    private var sscdId: String?
    private var sscdType: String?
    private var createdDate: Date?
    private var publicKey: PublicKey?
    private var certificate: MusapCertificate?
    private var certificateChain: [MusapCertificate]?
    private var attributes: [KeyAttribute]?
    private var keyUsages: [String]?
    private var loa: [MusapLoa]?
    private var algorithm: KeyAlgorithm?
    private var keyUri: KeyURI?
    private var isBiometricRequired: Bool
    private var did: String?
    private var state: String?
            
    public init(
        keyAlias:         String,
        keyType:          String? = nil,
        keyId:            String? = nil,
        sscdId:           String? = nil,
        sscdType:         String,
        createdDate:      Date = Date(),
        publicKey:        PublicKey,
        certificate:      MusapCertificate? = nil,
        certificateChain: [MusapCertificate]? = nil,
        attributes:       [KeyAttribute]? = nil,
        keyUsages:        [String]? = nil,
        loa:              [MusapLoa]? = nil,
        algorithm:        KeyAlgorithm? = nil,
        keyUri:           KeyURI?,
        isBiometricRequired: Bool = false,
        did:                 String? = nil,
        state:               String? = nil
        
    )
    {
        self.keyAlias         = keyAlias
        self.keyType          = keyType
        self.keyId            = keyId
        self.sscdId           = sscdId
        self.sscdType         = sscdType
        self.createdDate      = createdDate
        self.publicKey        = publicKey
        self.certificate      = certificate
        self.certificateChain = certificateChain
        self.attributes       = attributes
        self.keyUsages        = keyUsages
        self.loa              = loa
        self.algorithm        = algorithm
        self.keyUri           = keyUri
        self.isBiometricRequired = isBiometricRequired
        self.did              = did
        self.state            = state
    }
    
    
    // KeyAlias
    public func getKeyAlias() -> String? { keyAlias }
    public func setKeyAlias(value: String?) { keyAlias = value }

    // KeyType
    public func getKeyType() -> String? { keyType }
    public func setKeyType(value: String?) { keyType = value }

    // KeyId
    public func getKeyId() -> String? { keyId }
    public func setKeyId(value: String?) { keyId = value }

    // SscdId
    public func getSscdId() -> String? { sscdId }
    public func setSscdId(value: String?) { sscdId = value }

    // SscdType
    public func getSscdType() -> String? { sscdType }
    public func setSscdType(value: String?) { sscdType = value }

    // CreatedDate
    public func getCreatedDate() -> Date? { createdDate }
    public func setCreatedDate(value: Date?) { createdDate = value }

    // PublicKey
    public func getPublicKey() -> PublicKey? { publicKey }
    public func setPublicKey(value: PublicKey?) { publicKey = value }

    // Certificate
    public func getCertificate() -> MusapCertificate? { certificate }
    public func setCertificate(value: MusapCertificate?) { certificate = value }

    // CertificateChain
    public func getCertificateChain() -> [MusapCertificate]? { certificateChain }
    public func setCertificateChain(value: [MusapCertificate]?) { certificateChain = value }

    // Attributes
    public func getAttributes() -> [KeyAttribute]? { attributes }
    public func setAttributes(value: [KeyAttribute]?) { attributes = value }

    // KeyUsages
    public func getKeyUsages() -> [String]? { keyUsages }
    public func setKeyUsages(value: [String]?) { keyUsages = value }

    // Loa
    public func getLoa() -> [MusapLoa]? { loa }
    public func setLoa(value: [MusapLoa]?) { loa = value }

    // Algorithm
    public func getAlgorithm() -> KeyAlgorithm? { algorithm }
    public func setAlgorithm(value: KeyAlgorithm?) { algorithm = value }

    // KeyUri
    public func getKeyUri() -> KeyURI? { keyUri }
    public func setKeyUri(value: KeyURI?) { keyUri = value }

    // IsBiometricRequired
    public func getIsBiometricRequired() -> Bool { isBiometricRequired }
    public func setIsBiometricRequired(value: Bool) { isBiometricRequired = value }

    // Did
    public func getDid() -> String? { did }
    public func setDid(value: String?) { did = value }

    // State
    public func getState() -> String? { state }
    public func setState(value: String?) { state = value }
    
    public func getAttribute(attrName: String) -> KeyAttribute? {
        return self.attributes?.first { $0.name == attrName } ?? nil
    }
    
    public func getAttributeValue(attrName: String) -> String? {
        guard let attribute = self.getAttribute(attrName: attrName) else {
            AppLogger.shared.log("No value for attribute name: \(attrName)")
            return nil
        }
        return attribute.value
    }
    
    public func removeAttribute(nameToRemove: String) {
        guard var attributes = self.attributes else {
            AppLogger.shared.log("Key Attributes were nil, unable to remove")
            return
        }

        if let index = attributes.firstIndex(where: { $0.name == nameToRemove }) {
            attributes.remove(at: index)
            self.attributes = attributes
        }
    }

    /**
    Add a new attribute to a key. If there is an existing attribute with same name,
    this replaces the value with a new one
     */
    public func addAttribute(attr: KeyAttribute) {
        AppLogger.shared.log("Trying to add attribute: \(attr.name) with value: \(String(describing: attr.value))")
        
        // Initialize attributes array if nil
        if self.attributes == nil {
            self.attributes = []
        }
        
        // Update existing attribute if found
        if let index = self.attributes?.firstIndex(where: { $0.name.lowercased() == attr.name.lowercased() }) {
            self.attributes?[index] = attr
        } else {
            // Add new attribute
            self.attributes?.append(attr)
        }
        
        AppLogger.shared.log("Added attributes. Current attributes: \(String(describing: self.attributes))")
    }
    
    
    
    //TODO: finish
    public func getDefaultKeyAlgorithm() -> SecKeyAlgorithm {
        guard let algorithm = self.algorithm else {
            AppLogger.shared.log("Unable to determine algorithm for key: \(String(describing: self.keyAlias)) - Returning a guess", .warning)
            return SignatureAlgorithm.SHA256withECDSA
        }
        return SignatureAlgorithm.SHA256withECDSA

    }
    
    public func getSscdInfo() -> SscdInfo? {
        AppLogger.shared.log("Trying to get SSCD info")
        if (self.sscdId == nil) {
            AppLogger.shared.log("Unable to get SSCD info - no SSCD id", .error)
            return nil
        }
        
        for sscd in MusapClient.listActiveSscds() {
            if (self.sscdId == sscd.getSscdId()) {
                AppLogger.shared.log("Found SSCD info")
                return sscd.getSscdInfo()
            }
        }
        
        AppLogger.shared.log("Unable to get SSCD Info - SSCD not found")
        return nil
    }
    
    public func getSscd() -> MusapSscd? {
        AppLogger.shared.log("Trying to get SSCD")
        guard let sscdType = self.sscdType else {
            AppLogger.shared.log("Unable to get SSCD - no SSCD type found in ", .error)
            return nil
        }
        
        guard let enabledSscds = MusapClient.listEnabledSscds() else {
            AppLogger.shared.log("Unable to get SSCD - no enabled SSCD's", .error)
            return nil
        }
        
        AppLogger.shared.log("Trying to find SSCD with type: \(sscdType)")
        
        for sscd in enabledSscds {
            let sscdInfo = sscd.getSscdInfo()
            let sscdId   = sscd.getSettings().getSetting(forKey: "id")
            
            if sscdType == sscd.getSscdInfo()?.getSscdType() {
                // Found same type of SSCD
                if self.sscdId == nil {
                    AppLogger.shared.log("SSCD found!")
                    return sscd
                } else if self.sscdId == sscdId {
                    // Found a match by SSCD ID
                    AppLogger.shared.log("Found SSCD with type \(sscdType) and ID: \(String(describing: sscdId))")
                    return sscd
                } else {
                    AppLogger.shared.log("Found SSCD type did not match ours", .warning)
                }
            }
            
        }
        
        AppLogger.shared.log("Could not find SSCD implementation for key with id: \(self.keyId ?? "(empty ID)")")
        return nil
    }
    
}

