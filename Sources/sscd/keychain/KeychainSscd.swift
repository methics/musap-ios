//
//  KeychainSscd.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 14.11.2023.
//

import Foundation

public class KeychainSscd: MusapSscdProtocol {
    
    typealias CustomSscdSettings = KeychainSscdSettings
    
    static let SSCD_TYPE = "Keychain"
    
    private let settings = KeychainSscdSettings()
    
    func bindKey(req: KeyBindReq) throws -> MusapKey {
        fatalError("Unsupported operation")
    }
    
    func generateKey(req: KeyGenReq) throws -> MusapKey {
        print("Starting MusapKey generation")
        
        let sscd = self.getSscdInfo()
        
        guard req.keyAlgorithm != nil else {
            print("No key algorithm was set")
            throw MusapException(MusapError.internalError)
        }
        
        guard let algo = req.keyAlgorithm?.primitive,
              let bits = req.keyAlgorithm?.bits
        else {
            print("algorithm or bits were nil")
            throw MusapException(MusapError.invalidAlgorithm)
        }
        
        if self.doesKeyExistAlready(keyAlias: req.keyAlias) {
            print("Key exist with key alias: \(req.keyAlias)")
            throw MusapException.init(MusapError.internalError)
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
                print("Error creating private key: \(errorString as String?)")
            } else {
                print("No error? ")
            }
            
            throw MusapError.internalError
        }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            print("Unable to get public key from the private key")
            throw MusapError.internalError
        }
        
        guard let publicKeyData  = SecKeyCopyExternalRepresentation(publicKey, &error) as Data?,
              let publicKeyBytes = publicKeyData.withUnsafeBytes({ (ptr: UnsafeRawBufferPointer) in ptr.baseAddress })
        else {
            print("Could not form public key data")
            throw MusapError.internalError
        }
        
        let publicKeyObj = PublicKey(publicKey: Data(bytes: publicKeyBytes, count: publicKeyData.count))
        
        guard let keyAlgorithm = req.keyAlgorithm else {
            print("Key algorithm was not set in KeyGenReq, cant construct MusapKey")
            throw MusapError.internalError
        }
        
        let generatedKey = MusapKey(keyAlias: req.keyAlias,
                                    keyId: UUID().uuidString,
                                    sscdType: "Keychain",
                                    publicKey: publicKeyObj,
                                    loa: [MusapLoa.EIDAS_HIGH, MusapLoa.ISO_LOA2],
                                    algorithm: keyAlgorithm,
                                    //certificate: MusapCertificate(),
                                    keyUri: KeyURI(name: req.keyAlias, sscd: sscd.sscdType, loa: "loa2")
        )
                
                                    
                                    
        return generatedKey
    }
    
    func sign(req: SignatureReq) throws -> MusapSignature {
        guard let keyAlias = req.key.getKeyAlias() else {
            print("Signing failed: keyName was empty")
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
                print("key not found")
            } else {
                print("Keychain error with status: \(status)")
            }
            throw MusapError.internalError
        }
        
        let privateKey = item as! SecKey
        let dataToSign = req.data
        
        var error: Unmanaged<CFError>?
        
        guard let algorithm = req.algorithm.getAlgorithm() else {
            print("No algorithm in signature request")
            throw MusapError.invalidAlgorithm
        }
        
        guard let signature = SecKeyCreateSignature(privateKey, algorithm, dataToSign as CFData, &error)
        else {
            print("Signing failed")
            throw MusapError.internalError
        }
        
        let signatureData = signature as Data
        
        return MusapSignature(rawSignature: signatureData, key: req.key, algorithm: req.algorithm, format: req.format)
        
    }
    
    func getSscdInfo() -> MusapSscd {
        let musapSscd = MusapSscd(
            sscdName: "Keychain",
            sscdType: KeychainSscd.SSCD_TYPE,
            sscdId:   "Keychain",
            country:  "FI",
            provider: "Apple",
            keyGenSupported: true,
            algorithms: [KeyAlgorithm.RSA_2K,
                         KeyAlgorithm.ECC_P256_K1,
                         KeyAlgorithm.ECC_P256_R1,
                         KeyAlgorithm.ECC_P384_K1,
                         KeyAlgorithm.ECC_P256_R1],
            formats: [SignatureFormat.RAW])
        
        return musapSscd
    }
    
    func generateSscdId(key: MusapKey) -> String {
        return "keychain"
    }
    
    func isKeygenSupported() -> Bool {
        return self.getSscdInfo().keyGenSupported
    }
    
    func getSettings() -> [String : String]? {
        return self.settings.getSettings()
    }
    
    func getSettings() -> KeychainSscdSettings {
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
            print("Key seems to exist")
            return true
        } else if status == errSecItemNotFound {
            print("Key doesnt exist with keyname: \(keyAlias)")
            return false
        } else {
            print(status)
        }
        return false
    }
    
    
    
}
