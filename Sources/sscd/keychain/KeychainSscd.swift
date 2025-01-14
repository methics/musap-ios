//
//  KeychainSscd.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 14.11.2023.
//

import Foundation

public class KeychainSscd: MusapSscdProtocol {
    
    public typealias CustomSscdSettings = KeychainSscdSettings
    
    static let SSCD_TYPE = "Keychain"
    
    private let settings = KeychainSscdSettings()
    
    /// Required public init to make class on internal
    public init() {}
    
    public func bindKey(req: KeyBindReq) throws -> MusapKey {
        fatalError("Unsupported operation")
    }
    
    public func generateKey(req: KeyGenReq) throws -> MusapKey {
        AppLogger.shared.log("Starting MusapKey generation")
        
        let sscd = self.getSscdInfo()
        
        guard req.keyAlgorithm != nil else {
            AppLogger.shared.log("No algorithm was set, can't continue", .error)
            throw MusapException(MusapError.internalError)
        }
        
        guard let algo = req.keyAlgorithm?.primitive else {
            AppLogger.shared.log("No algorithm primitive was set, can't continue", .error)
            throw MusapError.invalidAlgorithm
        }
        
        guard let bits = req.keyAlgorithm?.bits else {
            AppLogger.shared.log("No algorithm bits was set, con't continue", .error)
            throw MusapError.invalidAlgorithm
        }
        
        if self.doesKeyExistAlready(keyAlias: req.keyAlias) {
            AppLogger.shared.log("Key already exists with key alias: \(req.keyAlias), can't continue")
            throw MusapError.keyAlreadyExists
        }
        
        let keyAttributes: [String: Any] =
               [kSecAttrKeyType       as String: algo,
                kSecAttrKeySizeInBits as String: bits,
                kSecPrivateKeyAttrs   as String: [
                       kSecAttrIsPermanent    as String: true,
                       kSecAttrApplicationTag as String: req.keyAlias.data(using: .utf8),
                       kSecAttrKeyClass       as String: kSecAttrKeyClassPrivate
                   ],
           ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(keyAttributes as CFDictionary, &error) else {
            if let errorRef = error {
                let error = errorRef.takeRetainedValue()
                let errorString = CFErrorCopyDescription(error)
                AppLogger.shared.log("Error creating private key: \(errorString as String?)", .error)
            }
            
            // can't continue
            throw MusapError.internalError
        }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            AppLogger.shared.log("Unable to get public key with SecKeyCopyPublicKey()", .error)
            throw MusapError.internalError
        }
        
        guard let publicKeyData  = SecKeyCopyExternalRepresentation(publicKey, &error) as Data?,
              let publicKeyBytes = publicKeyData.withUnsafeBytes({ (ptr: UnsafeRawBufferPointer) in ptr.baseAddress })
        else {
            AppLogger.shared.log("Could not form public key data", .error)
            throw MusapError.internalError
        }
        
        let publicKeyObj = PublicKey(publicKey: Data(bytes: publicKeyBytes, count: publicKeyData.count))
        
        guard let keyAlgorithm = req.keyAlgorithm else {
            AppLogger.shared.log("Key algorithm was not set in KeyGenReq, can't construct MusapKey", .error)
            throw MusapError.internalError
        }
        
        let generatedKey = MusapKey(keyAlias: req.keyAlias,
                                    keyId: UUID().uuidString,
                                    sscdType: "Keychain",
                                    publicKey: publicKeyObj,
                                    loa: [MusapLoa.EIDAS_HIGH, MusapLoa.ISO_LOA2],
                                    algorithm: keyAlgorithm,
                                    //certificate: MusapCertificate(),
                                    keyUri: KeyURI(name: req.keyAlias, sscd: sscd.getSscdType(), loa: "loa2")
        )
                
        return generatedKey
    }
    
    public func sign(req: SignatureReq) throws -> MusapSignature {
        AppLogger.shared.log("Starting to sign with KeychainSscd...")
        
        guard let keyAlias = req.key.getKeyAlias() else {
            AppLogger.shared.log("No key alias was set", .error)
            throw MusapError.internalError
        }
        
        let query: [String: Any] = [
            kSecClass              as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyAlias.data(using: .utf8)!,
            kSecAttrKeyClass       as String: kSecAttrKeyClassPrivate,
            kSecReturnRef          as String: true,
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                AppLogger.shared.log("Key not found", .error)
            } else {
                AppLogger.shared.log("Keychain error with status: \(status)")
            }
            throw MusapError.internalError
        }
        
        let privateKey = item as! SecKey
        let dataToSign = req.data
        
        var error: Unmanaged<CFError>?
        
        guard let algorithm = req.algorithm.getAlgorithm() else {
            AppLogger.shared.log("No algorithm was found in SignatuereReq", .error)
            throw MusapError.invalidAlgorithm
        }
        
        guard let signature = SecKeyCreateSignature(privateKey, algorithm, dataToSign as CFData, &error)
        else {
            AppLogger.shared.log("Signing failed, \(error.debugDescription)", .error)
            throw MusapError.internalError
        }
        
        let signatureData = signature as Data
        
        AppLogger.shared.log("Returning MusapSignature")
        return MusapSignature(rawSignature: signatureData, key: req.key, algorithm: req.algorithm, format: req.format)
    }
    
    public func getSscdInfo() -> SscdInfo {
        let musapSscd = SscdInfo(
            sscdName: "Keychain",
            sscdType: KeychainSscd.SSCD_TYPE,
            sscdId:   self.getSetting(forKey: "id"),
            country:  "FI",
            provider: "Apple",
            keygenSupported: true,
            algorithms: [KeyAlgorithm.RSA_2K,
                         KeyAlgorithm.ECC_P256_K1,
                         KeyAlgorithm.ECC_P256_R1,
                         KeyAlgorithm.ECC_P384_K1,
                         KeyAlgorithm.ECC_P256_R1],
            formats: [SignatureFormat.RAW])
        
        return musapSscd
    }
    
    public func generateSscdId(key: MusapKey) -> String {
        return "keychain"
    }
    
    public func isKeygenSupported() -> Bool {
        return self.getSscdInfo().isKeygenSupported()
    }
    
    public func getSettings() -> [String : String]? {
        return self.settings.getSettings()
    }
    
    public func getSettings() -> KeychainSscdSettings {
        return self.settings
    }
    
    private func doesKeyExistAlready(keyAlias: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyAlias.data(using: .utf8)!,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecReturnRef as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        // If the status is errSecSuccess, a matching item already exists.
        if status == errSecSuccess {
            AppLogger.shared.log("Key exists already", .warning)
            return true
        } else if status == errSecItemNotFound {
            AppLogger.shared.log("No key exists with this Key alias: \(keyAlias)")
            return false
        } else {
            AppLogger.shared.log("Status: \(status)", .info)
        }
        return false
    }
    
    public func getSetting(forKey key: String) -> String? {
        return self.settings.getSetting(forKey: key)
    }
    
    public func setSetting(key: String, value: String) {
        self.settings.setSetting(key: key, value: value)
    }
    
    public func getKeyAttestation() -> any KeyAttestationProtocol {
        return NoKeyAttestation()
    }
    
    public func attestKey(key: MusapKey) -> KeyAttestationResult {
        return KeyAttestationResult(attestationStatus: .INVALID)
    }
    
    
    
    
}
