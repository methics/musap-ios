//
//  SecureEnclaveSscd.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 6.11.2023.
//

import Foundation
import Security
import CommonCrypto

public class SecureEnclaveSscd: MusapSscdProtocol {
    
    public typealias CustomSscdSettings = SecureEnclaveSettings
    
    static let SSCD_TYPE = "SE"
    
    private let settings = SecureEnclaveSettings()
    
    /// Required public init to make class on internal
    public init() {}
    
    public func bindKey(req: KeyBindReq) throws -> MusapKey {
        // Old keys cannot be bound to musap?
        // Use generateKey instead
        fatalError("Unsupported operation")
    }

    public func generateKey(req: KeyGenReq) throws -> MusapKey {
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
        
        guard algo as CFString == kSecAttrKeyTypeECSECPrimeRandom,
              bits == 256 || bits == 384 || bits == 512
        else {
            print("Algorithm was not kSecAttrKeyTypeECSECPrimeRandom, or bits wasnt 256")
            throw MusapException(MusapError.invalidAlgorithm)
        }
        
        if self.doesKeyExistAlready(keyAlias: req.keyAlias) {
            print("Key exists with this keyname \(req.keyAlias)")
            throw MusapError.keyAlreadyExists
        }
        
        let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage, /*.biometryCurrentSet TODO: Make this value come from Settings??*/],
            nil)
        
        let keyAttributes: [String: Any] = [
            kSecAttrKeyType as String: algo,
            kSecAttrKeySizeInBits as String: bits,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrAccessControl as String: accessControl,
                kSecAttrApplicationTag as String: req.keyAlias.data(using: .utf8)
            ]
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
        
        print("SE publicKeyData: \(publicKeyData.base64EncodedString())")
        print("SE publicKeyBites: \(Data(bytes: publicKeyBytes, count: publicKeyData.count).base64EncodedString())")
        
        guard let keyAlgorithm = req.keyAlgorithm else {
            print("Key algorithm was not set in KeyGenReq, cant construct MusapKey")
            throw MusapError.internalError
        }
        
        let publicKeyObj = PublicKey(publicKey: Data(bytes: publicKeyBytes, count: publicKeyData.count))
        let generatedKey = MusapKey(keyAlias:     req.keyAlias,
                                    keyId:       UUID().uuidString,
                                    sscdId:      sscd.getSscdId(),
                                    sscdType:    MusapConstants.IOS_KS_TYPE,
                                    publicKey:   publicKeyObj,
                                    //certificate: MusapCertificate(),
                                    attributes:  req.attributes,
                                    loa:         [MusapLoa.EIDAS_SUBSTANTIAL, MusapLoa.ISO_LOA3],
                                    algorithm:   keyAlgorithm,
                                    keyUri:      KeyURI(name: req.keyAlias, sscd: sscd.getSscdType(), loa: "loa3")

        )
        print("MusapKey generated!")
        return generatedKey
    }
    
    public func sign(req: SignatureReq) throws -> MusapSignature {
        guard let keyAlias = req.key.getKeyAlias() else {
            print("Signing failed: keyName was empty")
            throw MusapError.internalError
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyAlias.data(using: .utf8)!,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecReturnRef as String: true,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave
        ]
        

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            print("Could not find key")
            throw MusapError.internalError
        }
        
        let privateKey = item as! SecKey
        let dataToSign = req.data
        //let dataToSign = self.hashDataWithSHA512(data: req.data)
        /* FIXME SecKeyCreateSignature already hashes the data.
         * Double-hashing will break the dataToBeSigned making it impossible to sign objects like JWTs.
         * If there is a use case for doing an extra round of SHA512 hashing there should be a flag for it in SignatureReq
        */

        var error: Unmanaged<CFError>?
        
        /*
         Allowed signature algos:
            - ecdsaSignatureDigestX962
            - ecdsaSignatureDigestX962SHA256 OK
            - ecdsaSignatureDigestX962SHA384
            - ecdsaSignatureDigestX962SHA512
            - ecdsaSignatureMessageX962SHA256
            Can check with SecKeyIsAlgorithmSupported():
                https://developer.apple.com/documentation/security/1644057-seckeyisalgorithmsupported
         */
        
        
        
        //TODO: Optionally support requiring biometric authentication to allow using the keys
        
        guard let signAlgorithm = req.algorithm.getAlgorithm() else {
            print("No sign algorithm in SignatureReq")
            throw MusapError.internalError
        }
        
        guard let signature = SecKeyCreateSignature(privateKey, signAlgorithm, dataToSign as CFData, &error) else {
            print("Signing failed while SecKeyCreateSignature \(error)")
            throw MusapError.internalError
        }
                
        let signatureData = signature as Data
        
        return MusapSignature(rawSignature: signatureData, key: req.getKey(), algorithm: SignatureAlgorithm.init(algorithm: .ecdsaSignatureMessageX962SHA256), format: SignatureFormat.RAW)
    }
    
    public func getSscdInfo() -> SscdInfo {
        let musapSscd = SscdInfo(
            sscdName:        "SE",
            sscdType:        SecureEnclaveSscd.SSCD_TYPE,
            sscdId:          self.getSetting(forKey: "id"),
            country:         "FI",
            provider:        "Apple",
            keygenSupported: true,
            algorithms:      [KeyAlgorithm.RSA_2K,
                             KeyAlgorithm.ECC_P256_K1,
                             KeyAlgorithm.ECC_P256_R1,
                             KeyAlgorithm.ECC_P384_K1,
                             KeyAlgorithm.ECC_P256_R1],
            formats:         [SignatureFormat.RAW])
        return musapSscd
    }
    
    public func isKeygenSupported() -> Bool {
        return self.getSscdInfo().isKeygenSupported()
    }
    
    public func getSettings() -> SecureEnclaveSettings {
        return self.settings
    }
    
    public func getSettings() -> [String : String]? {
        return self.settings.getSettings()
    }
    
    public func resolveAlgorithmParameterSpec(req: KeyGenReq) -> SecKeyAlgorithm? {
        guard let algorithm = req.keyAlgorithm else {
            return SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
        }
        
        if algorithm.isRsa() {
            return SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256
        } else {
            return SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
        }
    }
    
    private func resolveAlgorithm(req: KeyGenReq) -> String {
        let algorithm = req.keyAlgorithm
        
        guard let algorithm = req.keyAlgorithm else {
            return KeyAlgorithm.PRIMITIVE_EC
        }
        if algorithm.isRsa() { return KeyAlgorithm.PRIMITIVE_RSA }
        if algorithm.isEc()  { return KeyAlgorithm.PRIMITIVE_EC  }
        return KeyAlgorithm.PRIMITIVE_EC
    }
    
    private func doesKeyExistAlready(keyAlias: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
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
    
    func hashDataWithSHA256(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
    
    func hashDataWithSHA384(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA384_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA384($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
    
    func hashDataWithSHA512(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA512($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
    
    public func getSetting(forKey key: String) -> String? {
        self.settings.getSetting(forKey: key)
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
