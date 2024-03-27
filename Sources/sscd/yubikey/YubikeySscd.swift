//
//  YubikeySscd.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 22.11.2023.
//

import Foundation
import YubiKit
import SwiftUI

public class YubikeySscd: MusapSscdProtocol {
    
    public typealias CustomSscdSettings = YubikeySscdSettings
    private let settings = YubikeySscdSettings()
    
    private static let ATTRIBUTE_ATTEST = "YubikeyAttestationCert"
    private static let ATTRIBUTE_SERIAL = "serial"
    private static let MANAGEMENT_KEY_TYPE: YKFPIVManagementKeyType = YKFPIVManagementKeyType.tripleDES()
    private static let MANAGEMENT_KEY = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
    static let         SSCD_TYPE = "Yubikey"
    private static let yubiKeyConnection = YubiKeyConnection()
    
    private let type: YKFPIVManagementKeyType
    private let yubiKitManager: YubiKitManager
    private var attestationCertificate: [String: Data]?
    private var attestationSecCertificate: SecCertificate?
    private var generatedKeyId: String?
    
    
    var onRequirePinEntry: ((_ completion: @escaping (String) -> Void) -> Void)?
    
    public init() {
        self.yubiKitManager = YubiKitManager.shared
        self.type = YubikeySscd.MANAGEMENT_KEY_TYPE
    }
    
    public func bindKey(req: KeyBindReq) throws -> MusapKey {
        throw MusapError.bindUnsupported
    }
    
    public func generateKey(req: KeyGenReq) throws -> MusapKey {
        let sscd = self.getSscdInfo()
        
        var thePin: String? = nil
        let semaphore = DispatchSemaphore(value: 0)
        
        YubikeySscd.displayEnterPin { pin in
            print("Received PIN: \(pin)")
            semaphore.signal()
            thePin = pin
        }

        semaphore.wait()
        guard let pin = thePin else {
            throw MusapError.internalError
        }
        
        var musapKey: MusapKey?
        var generationError: Error?
        
        let group = DispatchGroup()
        group.enter()
        
        print("trying to generate key with yubikey...")
        self.yubiKeyGen(pin: pin, req: req) { result in
            switch result {
            case .success(let publicKey):
                
                var pubKeyError: Unmanaged<CFError>?
                
                guard let publicKeyData  = SecKeyCopyExternalRepresentation(publicKey, &pubKeyError) as Data?,
                      let publicKeyBytes = publicKeyData.withUnsafeBytes({ (ptr: UnsafeRawBufferPointer) in ptr.baseAddress })
                else {
                    print("Could not form public key data")
                    generationError = MusapError.internalError
                    return
                }
                
                let publicKeyObj = PublicKey(publicKey: Data(bytes: publicKeyBytes, count: publicKeyData.count))
                
                guard let keyAlgorithm = req.keyAlgorithm else {
                    print("Key algorithm was not set in KeyGenReq, cant construct MusapKey")
                    generationError = MusapError.invalidAlgorithm
                    return
                }
                
                guard let attestationSecCert = self.attestationSecCertificate else {
                    print("No key attestation certificate found")
                    return
                }
                
                let keyAttribute = KeyAttribute(name: YubikeySscd.ATTRIBUTE_ATTEST, cert: attestationSecCert)
                
                musapKey = MusapKey(keyAlias:  req.keyAlias,
                                    keyId:     self.generatedKeyId,
                                    sscdType:  YubikeySscd.SSCD_TYPE,
                                    publicKey: publicKeyObj,
                                    attributes: [keyAttribute],
                                    loa: [MusapLoa.EIDAS_SUBSTANTIAL, MusapLoa.ISO_LOA3],
                                    algorithm: keyAlgorithm,
                                    keyUri:    KeyURI(name: req.keyAlias, sscd: sscd.getSscdType(), loa: "loa2")
                )
                
                break
                
            case .failure(let error):
                print(error)
                generationError = error
            }
            
            group.leave()
        }
        
        group.wait()
        
        if let error = generationError {
            throw error
        }
        
        guard let generatedKey = musapKey else {
            throw MusapError.internalError
        }
        
        return generatedKey
    }
    
    public func sign(req: SignatureReq) throws -> MusapSignature {
        print("Trying to sign with YubiKey")
        var thePin: String? = nil
        let semaphore = DispatchSemaphore(value: 0)
        
        YubikeySscd.displayEnterPin { pin in
            thePin = pin
            print("Got PIN: \(pin)")
            semaphore.signal()
        }
        
        semaphore.wait()
        
        guard let pin = thePin else {
            print("PIN error")
            throw MusapError.internalError
        }
        
        let group = DispatchGroup()
        group.enter()
        
        var musapSignature: MusapSignature?
        var signError: Error?
        
        print("Running yubiSign()")
        self.yubiSign(pin: pin, req: req) { result in
            
            switch result {
            case .success(let data):
                musapSignature = MusapSignature(rawSignature: data, key: req.getKey(), algorithm: req.algorithm, format: req.format)
            case .failure(let error):
                print("error: \(error.localizedDescription)")
                signError = error
            }
            
            group.leave()
        }
        
        group.wait()
        
        if let error = signError {
            throw error
        }
        
        guard let signature = musapSignature else {
            throw MusapError.internalError
        }
        
        return signature
    }
    
    public func getSscdInfo() -> SscdInfo {
        let musapSscd = SscdInfo(sscdName:        "Yubikey",
                                  sscdType:        YubikeySscd.SSCD_TYPE,
                                  sscdId:          self.getSetting(forKey: "id"),
                                  country:         "FI",
                                  provider:        "Yubico",
                                  keygenSupported: true,
                                  algorithms:      [KeyAlgorithm.ECC_P256_K1, KeyAlgorithm.ECC_P384_K1],
                                  formats:         [SignatureFormat.RAW]
        )
        return musapSscd
    }
    
    public func generateSscdId(key: MusapKey) -> String {
        guard let attributeValue = key.getAttributeValue(attrName: YubikeySscd.ATTRIBUTE_SERIAL) else {
            return YubikeySscd.SSCD_TYPE
        }
        
        return YubikeySscd.SSCD_TYPE + "/\(attributeValue)"
    }
    
    public func isKeygenSupported() -> Bool {
        true
    }
    
    public func getSettings() -> [String : String]? {
        return settings.getSettings()
    }
    
    public func getSettings() -> YubikeySscdSettings {
        return self.settings
    }
    
    private func yubiKeyGen(pin: String, req: KeyGenReq, completion: @escaping (Result<SecKey, Error>) -> Void ) {
        let yubiKeyconnection = YubiKeyConnection()
        
        yubiKeyconnection.connection { connection in
            
            if let nfcConnection = yubiKeyconnection.nfcConnection {
                nfcConnection.pivSession { session, error in
                    guard let session = session else {
                        print("Could not get pivSession")
                        return
                    }
                    
                    // We have PIV session
                    session.authenticate(withManagementKey: YubikeySscd.MANAGEMENT_KEY, type: .tripleDES()) { error in
                        guard error == nil else {
                            print("error in yubikey authentication: \(String(describing: error))")
                            return
                        }
                        
                        // Authentication OK with management key
                        //TODO: Will these come from user app in the future? (slot, pin & touch policy)
                        let slot        = YKFPIVSlot.signature
                        let pinPolicy   = YKFPIVPinPolicy.default
                        let touchPolicy = YKFPIVTouchPolicy.default
                        let keyType     = self.selectKeyType(req: req)
                        
                        session.generateKey(in: slot, type: keyType, pinPolicy: pinPolicy, touchPolicy: touchPolicy) { publicKey, error in
                            
                            session.attestKey(in: slot) { cert, error in
                                
                                if error != nil {
                                    print("Error while key attesting: \(String(describing: error))")
                                }
                                if let cert = cert {
                                    if let certData = SecCertificateCopyData(cert) as Data? {
                                        let keyId = UUID().uuidString
                                        self.generatedKeyId = keyId
                                        self.attestationCertificate = [keyId: certData]
                                        self.attestationSecCertificate = cert
                                    } else {
                                        print("failed to SecCertificateCopyData")
                                    }
                                } else {
                                    // failed attestation
                                    print("Failed YubikeyAttestation")
                                }
                            }
                        
                            // verify user PIN
                            session.verifyPin(pin, completion: { retries, error in
                
                                if let error = error {
                                    var errorMsg = error.localizedDescription
                                    if retries > 0 {
                                        errorMsg = error.localizedDescription + " Retries left: \(retries)"
                                    }
                                    
                                    YubiKitManager.shared.stopNFCConnection(withErrorMessage: errorMsg)
                                    completion(.failure(error))
                                    return
                                }
                                
                                YubiKitManager.shared.stopNFCConnection(withMessage: "KeyPair generated")
                                                                
                                if let pubKey = publicKey {

                                    
                                    
                                    completion(.success(pubKey))
                                } else {
                                    completion(.failure(MusapError.keygenUnsupported))
                                }
                                
                            })
                        
                            // Generate Key error
                            if let error = error {
                                print("Key generation failed")
                                completion(.failure(MusapError.internalError))
                                return
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func yubiSign(pin: String, req: SignatureReq, completion: @escaping (Result<Data, Error>) -> Void) {
        let yubiKeyConnection = YubiKeyConnection()
        
        yubiKeyConnection.connection { connection in
            
            if let nfcConnection = yubiKeyConnection.nfcConnection {
                connection.pivSession { session, error in
                    
                    if let error = error {
                        print("pivSession error: \(error)")
                        completion(.failure(error))
                    }

                    guard let session = session else {
                        print("Could not get piv session")
                        YubiKitManager.shared.stopNFCConnection(withErrorMessage: "Could not get PIV session")
                        return
                    }
                    
                    // Piv session OK
                    
                    // Now authenticate with management key so we can use sign function
                    session.authenticate(withManagementKey: YubikeySscd.MANAGEMENT_KEY, type: .tripleDES()) { error in
                        
                        // verify users PIN
                        session.verifyPin(pin) { retries, error in
                            
                            if let error = error {
                                var errorMsg = error.localizedDescription
                                if retries > 0 {
                                    errorMsg = error.localizedDescription + " Retries left: \(retries)"
                                }
                                print("VerifyPin failed: \(String(describing: error)) Retries left: \(retries)")
                                YubiKitManager.shared.stopNFCConnection(withErrorMessage: errorMsg)
                                completion(.failure(error))
                                return
                            } else {
                                print("YubiKey PIN verified successfully")
                            }
                            
                            guard let algorithm = req.algorithm.getAlgorithm() else {
                                print("No algorithm in SignatureRequest")
                                YubiKitManager.shared.stopNFCConnection(withErrorMessage: "Unknown signature algorithm")
                                completion(.failure(MusapError.invalidAlgorithm))
                                return
                            }
                            
                            let keyType = self.selectKeyType(req: req)
                            
                            
                            // Sign with key in signature slot
                            // Available slots:
                            // - YKFPIVSlot.signature
                            // - YKFPIVSlot.authentication
                            // - YKFPIVSlot.cardAuth
                            // - YKFPIVSlot.keyManagement
                            // - YKFPIVSlot.attestation
                            session.signWithKey(in: .signature, type: keyType, algorithm: algorithm, message: req.data) {
                                signature, error in
                                
                                guard let signature = signature else {
                                    if let error = error  {
                                        print("Signing failed: \(error.localizedDescription)")
                                        YubiKitManager.shared.stopNFCConnection(withErrorMessage: error.localizedDescription)
                                        completion(.failure(error))
                                        
                                    }
                                    return
                                }
                                
                                YubiKitManager.shared.stopNFCConnection()
                                completion(.success(signature))
                                return
                            }
                        }
                        
                        if let error = error {
                            print("yubikey authentication error: \(String(describing: error.localizedDescription))")
                            completion(.failure(error))
                            return
                        }

                    }
                }
            }
        }
    }
    

    /**
         Turn (MUSAP) KeyAlgorithm to YubiKey YKFPIVKeyType
     */
    private func selectKeyType(req: KeyGenReq) -> YKFPIVKeyType {
        if let keyAlgorithm = req.keyAlgorithm {
          
            if keyAlgorithm.isEc() {
                if keyAlgorithm.bits == 256 { return YKFPIVKeyType.ECCP256 }
                if keyAlgorithm.bits == 384 { return YKFPIVKeyType.ECCP384 }
            }
            
            if keyAlgorithm.isRsa() {
                if keyAlgorithm.bits == 1024 { return YKFPIVKeyType.RSA1024 }
                if keyAlgorithm.bits == 2048 { return YKFPIVKeyType.RSA2048 }
            }
            
        }
        
        return YKFPIVKeyType.unknown
        
    }
    
    private func selectKeyType(req: SignatureReq) -> YKFPIVKeyType {
        
        if let keyAlgorithm = req.getKey().getAlgorithm() {
            if keyAlgorithm.isEc() {
                if keyAlgorithm.bits == 256 { return YKFPIVKeyType.ECCP256 }
                if keyAlgorithm.bits == 384 { return YKFPIVKeyType.ECCP384 }
            }

            if keyAlgorithm.isRsa() {
                if keyAlgorithm.bits == 1024 { return YKFPIVKeyType.RSA1024 }
                if keyAlgorithm.bits == 2048 { return YKFPIVKeyType.RSA2048 }
            }
        } else {
        }
        print("Couldnt detect key algorithm")
        return YKFPIVKeyType.unknown
    }
    
    
    /**
     Displays Enter PIN prompt for the user
     Usage:
     YubiKeySscd.displayEnterPin { pin in
         print("Received PIN: \(pin)")
         // Handle the received PIN
     }
     */
    private static func displayEnterPin(completion: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene

            if let rootViewController = windowScene?.windows.first?.rootViewController {
                let pinInputView = PINInputView { pin in
                    completion(pin)
                    rootViewController.dismiss(animated: true, completion: nil)
                }
                
                let hostingController = UIHostingController(rootView: pinInputView)

                hostingController.modalPresentationStyle = .fullScreen // or as per your requirement
                rootViewController.present(hostingController, animated: true, completion: nil)
            }
        }
    }
    
    public func getSetting(forKey key: String) -> String? {
        self.settings.getSetting(forKey: key)
    }
    
    public func setSetting(key: String, value: String) {
        self.settings.setSetting(key: key, value: value)
    }
    
    public func getKeyAttestation() -> any KeyAttestationProtocol {
        return YubiKeyAttestation(keyAttestationType: KeyAttestationType.YUBIKEY, certificates: self.attestationCertificate)
    }
    
    public func attestKey(key: MusapKey) -> KeyAttestationResult {
        return self.getKeyAttestation().getAttestationData(key: key)
    }
    
}


