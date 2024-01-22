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
    private var attestation: KeyAttestation?
    private var isBiometricRequired: Bool
    private var did: String?
    private var state: String?
            
    init(
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
        keyUri:           KeyURI,
        attestation:      KeyAttestation? = nil,
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
        self.attestation      = attestation
        self.isBiometricRequired = isBiometricRequired
        self.did              = did
        self.state            = state
    }
    
    
    // KeyAlias
    func getKeyAlias() -> String? { keyAlias }
    func setKeyAlias(value: String?) { keyAlias = value }

    // KeyType
    func getKeyType() -> String? { keyType }
    func setKeyType(value: String?) { keyType = value }

    // KeyId
    func getKeyId() -> String? { keyId }
    func setKeyId(value: String?) { keyId = value }

    // SscdId
    func getSscdId() -> String? { sscdId }
    func setSscdId(value: String?) { sscdId = value }

    // SscdType
    func getSscdType() -> String? { sscdType }
    func setSscdType(value: String?) { sscdType = value }

    // CreatedDate
    func getCreatedDate() -> Date? { createdDate }
    func setCreatedDate(value: Date?) { createdDate = value }

    // PublicKey
    func getPublicKey() -> PublicKey? { publicKey }
    func setPublicKey(value: PublicKey?) { publicKey = value }

    // Certificate
    func getCertificate() -> MusapCertificate? { certificate }
    func setCertificate(value: MusapCertificate?) { certificate = value }

    // CertificateChain
    func getCertificateChain() -> [MusapCertificate]? { certificateChain }
    func setCertificateChain(value: [MusapCertificate]?) { certificateChain = value }

    // Attributes
    func getAttributes() -> [KeyAttribute]? { attributes }
    func setAttributes(value: [KeyAttribute]?) { attributes = value }

    // KeyUsages
    func getKeyUsages() -> [String]? { keyUsages }
    func setKeyUsages(value: [String]?) { keyUsages = value }

    // Loa
    func getLoa() -> [MusapLoa]? { loa }
    func setLoa(value: [MusapLoa]?) { loa = value }

    // Algorithm
    func getAlgorithm() -> KeyAlgorithm? { algorithm }
    func setAlgorithm(value: KeyAlgorithm?) { algorithm = value }

    // KeyUri
    func getKeyUri() -> KeyURI? { keyUri }
    func setKeyUri(value: KeyURI?) { keyUri = value }

    // Attestation
    func getAttestation() -> KeyAttestation? { attestation }
    func setAttestation(value: KeyAttestation?) { attestation = value }

    // IsBiometricRequired
    func getIsBiometricRequired() -> Bool { isBiometricRequired }
    func setIsBiometricRequired(value: Bool) { isBiometricRequired = value }

    // Did
    func getDid() -> String? { did }
    func setDid(value: String?) { did = value }

    // State
    func getState() -> String? { state }
    func setState(value: String?) { state = value }
    
    func getSscdImplementation() -> (any MusapSscdProtocol)? {
        let sscdType = self.sscdType
        print("Looking for SSCD with type: \(String(describing: sscdType))")
        
        let enabledSscds = MusapClient.listEnabledSscds()
        
        print("enabledSscds count: \(String(describing: enabledSscds?.count))")
        
        for sscd in enabledSscds! {
            print("sscd found: \(sscd.getSscdInfo().sscdType ?? "sscdType = nil")")
            //TODO: SSCD Type should never be nil
            guard let sscdType = sscd.getSscdInfo().sscdId else {
                print("SSCD type not set!")
                return nil
            }
            
            if (self.sscdType == sscdType) {
                return sscd
            } else {
                print("SSCD " + sscdType + " does not match " + self.sscdType! + ". Continue loop..." )
            }
        }
        
        return nil
    }
    
    public func getAttribute(attrName: String) -> KeyAttribute? {
        return self.attributes?.first { $0.name == attrName } ?? nil
    }
    
    public func getAttributeValue(attrName: String) -> String? {
        guard let attribute = self.getAttribute(attrName: attrName) else {
            print("No value for attribute name: \(attrName)")
            return nil
        }
        return attribute.value
    }
    
    public func removeAttribute(nameToRemove: String) {
        guard var attributes = self.attributes else {
            print("Attributes were nil")
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
        if var oldAttributes = self.attributes {
            
            for var oldAttr in oldAttributes {
                
                if oldAttr.name.lowercased() == attr.name.lowercased() {
                    oldAttr.value = attr.value
                    self.attributes = oldAttributes
                    return
                }
                
            }
            
            self.attributes = oldAttributes
        }
        
    }
    
    
    
    //TODO: finish
    public func getDefaultKeyAlgorithm() -> SecKeyAlgorithm {
        guard let algorithm = self.algorithm else {
            print("Unable to determine algorithm for key: \(String(describing: self.keyAlias))")
            return SignatureAlgorithm.SHA256withECDSA
        }
        return SignatureAlgorithm.SHA256withECDSA

    }
    
    public func getSscdInfo() -> MusapSscd? {
        if (self.sscdId == nil) { return nil }
        
        for sscd in MusapClient.listActiveSscds() {
            if (self.sscdId == sscd.sscdId) {
                return sscd
            }
        }
        
        return nil
    }
    
}

