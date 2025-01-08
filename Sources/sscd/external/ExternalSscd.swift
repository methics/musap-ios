//
//  ExternalSscd.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 5.1.2024.
//

import Foundation
import SwiftUI
import Security

/**
 * SSCD that uses MUSAP Link to request signatures with the "externalsign" Coupling API call
 */
public class ExternalSscd: MusapSscdProtocol {

    public typealias CustomSscdSettings = ExternalSscdSettings
    
    static let SSCD_TYPE           = "External Signature"
    static let ATTRIBUTE_MSISDN    = "msisdn"
    static let SIGN_MSG_TYPE       = "externalsignature"
    private static let POLL_AMOUNT = 10
    
    private let clientid:  String
    private let settings:  ExternalSscdSettings
    private let musapLink: MusapLink
    
    private var attestationSecCertificate: SecCertificate?
    
    public init(settings: ExternalSscdSettings, clientid: String, musapLink: MusapLink) {
        self.settings = settings
        self.clientid = settings.getClientId() ?? "LOCAL"
        self.musapLink = settings.getMusapLink()!
    }
    
    public func bindKey(req: KeyBindReq) throws -> MusapKey {
        AppLogger.shared.log("Starting bindKey...")
        
        let request: ExternalSignaturePayload = ExternalSignaturePayload(clientid: self.clientid)
        
        var theMsisdn: String? = nil
        let msisdn = req.getAttribute(name: ExternalSscd.ATTRIBUTE_MSISDN)
        
        let semaphore = DispatchSemaphore(value: 0)
        if msisdn == nil {
            AppLogger.shared.log("No MSISDN found, displaying UI to get it...")
            ExternalSscd.showEnterMsisdnDialog { msisdn in
                theMsisdn = msisdn
                semaphore.signal()
            }
        } else {
            theMsisdn = msisdn
            semaphore.signal()
        }
        
        semaphore.wait()
        
        let data = "Bind Key".data(using: .utf8)
        guard let base64Data = data?.base64EncodedString(options: .lineLength64Characters) else {
            AppLogger.shared.log("Unable to bind key, invalid data")
            throw MusapError.internalError
        }
        
        request.data     = base64Data
        request.clientid = self.clientid
        request.display  = req.getDisplayText()
        request.format   = "RAW"

        request.attributes = [String: String]()
        request.attributes![ExternalSscd.ATTRIBUTE_MSISDN] = theMsisdn
        
        do {
            var theKey: MusapKey?
            
            let signSemaphore = DispatchSemaphore(value: 0)
            self.musapLink.sign(payload: request) { result in
                
                switch result {
                case .success(let response):
                    
                    guard let signature = response.signature else {
                        AppLogger.shared.log("Unable to bind key, no signature", .error)
                        return
                    }
                            
                    guard let signatureData = signature.data(using: .utf8) else {
                        AppLogger.shared.log("Unable to turn signature to Data()", .error)
                        return
                    }
                                         
                    guard let publickey = response.publickey else {
                        AppLogger.shared.log("No public key in result", .error)
                        return
                    }
                    
                    guard let certStr = response.certificate,
                          let certData = Data(base64Encoded: certStr),
                          let secCertificate = SecCertificateCreateWithData(nil, certData as CFData)
                    else
                    {
                        AppLogger.shared.log("No certificate in result", .error)
                        return
                    }
                    
                    guard let certificateChain = response.certificateChain else {
                        AppLogger.shared.log("No certificate chain in result", .error)
                        return
                    }
                    
                    var musapCertChain: [MusapCertificate] = [MusapCertificate]()
                    
                    for cert in certificateChain {

                        guard let certData = Data(base64Encoded: cert),
                              let secCert = SecCertificateCreateWithData(nil, certData as CFData)
                        else 
                        {
                            AppLogger.shared.log("Unable to create SecCertificate from cert base64", .error)
                            return
                        }
                        
                        guard let newMusapCert = MusapCertificate(cert: secCert) else {
                            AppLogger.shared.log("Failed to create MusapCertificate with secCert", .error)
                            return
                        }
                        
                        musapCertChain.append(newMusapCert)
                    }
                    
                    self.attestationSecCertificate = secCertificate
            
                    guard let publicKeyData = Data(base64Encoded: publickey) else {
                        AppLogger.shared.log("Invalid base64 encoded public key", .error)
                        return
                    }
                    
                    theKey =  MusapKey(
                        keyAlias:  req.getKeyAlias(),
                        keyId:     UUID().uuidString,
                        sscdType:  ExternalSscd.SSCD_TYPE,
                        publicKey: PublicKey(publicKey: publicKeyData),
                        certificate: MusapCertificate(cert: secCertificate),
                        certificateChain: musapCertChain,
                        algorithm: KeyAlgorithm.RSA_2K,  //TODO: resolve this
                        keyUri: nil
                    )
                    
                case .failure(let error):
                    AppLogger.shared.log("Error while binding key: \(error)")
    
                }
                signSemaphore.signal()
            }
            signSemaphore.wait()
        
            guard let musapKey = theKey else {
                AppLogger.shared.log("Unable to bind key, no MUSAP key", .error)
                throw MusapError.internalError
            }
            
            let keyUri = KeyURI(key: musapKey)
            musapKey.setKeyUri(value: keyUri)
            musapKey.addAttribute(attr: KeyAttribute(name: ExternalSscd.ATTRIBUTE_MSISDN, value: theMsisdn))
            
            guard let attestationCert = self.attestationSecCertificate else {
                AppLogger.shared.log("No attestation certificate found", .error)
                throw MusapError.internalError
            }
            
            let attestAttr = KeyAttribute(name: "ATTEST", cert: attestationCert)
            musapKey.addAttribute(attr: attestAttr)
            return musapKey

        } catch {
            AppLogger.shared.log("Error in bind key: \(error)", .error)
        }
        
        // If we get to here, some error happened
        throw MusapError.internalError
    }
    
    public func generateKey(req: KeyGenReq) throws -> MusapKey {
        fatalError("Unsupported Operation")
    }
    
    public func sign(req: SignatureReq) throws -> MusapSignature {
        AppLogger.shared.log("Starting to sign with ExternalSscd...")
        
        let request = ExternalSignaturePayload(clientid: self.clientid)
        
        var theMsisdn: String? = nil // Eventually this gets set into the attributes
        let msisdn = req.key.getAttributeValue(attrName: ExternalSscd.ATTRIBUTE_MSISDN)
        
        let semaphore = DispatchSemaphore(value: 0)
        if msisdn == nil {
            ExternalSscd.showEnterMsisdnDialog { msisdn in
                AppLogger.shared.log("Received MSISDN: \(msisdn)")
                theMsisdn = msisdn
                semaphore.signal()
            }
        } else {
            theMsisdn = msisdn
            semaphore.signal()
        }
        
        semaphore.wait()
        
        let dataBase64 = req.getData().base64EncodedString(options: .lineLength64Characters)

        request.attributes = Dictionary(uniqueKeysWithValues:
            req.attributes.map { ($0.name, $0.value) }
        )
                
        request.attributes?[ExternalSscd.ATTRIBUTE_MSISDN] = theMsisdn
        request.clientid = self.clientid
        request.display  = req.getDisplayText()
        request.format   = req.getFormat().getFormat()
        request.data     = dataBase64
        
        AppLogger.shared.log("Signature Attributes: \(String(describing: request.attributes))")

        do {
            var theSignature: MusapSignature?
            
            let signSemaphore = DispatchSemaphore(value: 0)
            self.musapLink.sign(payload: request) { result in
                
                switch result {
                case .success(let response):
                    AppLogger.shared.log("Signing was success: \(response.isSuccess())")
                    guard let rawSignature = response.getRawSignature() else {
                        AppLogger.shared.log("No raw signature found!", .error)
                        return
                    }

                    theSignature = MusapSignature(rawSignature: rawSignature, key: req.getKey(), algorithm: req.algorithm, format: req.format)
                    
                case .failure(let error):
                    AppLogger.shared.log("Error in signing: \(error)")
                }
                
                signSemaphore.signal()
            }
            
            signSemaphore.wait()
            guard let signature = theSignature else {
                AppLogger.shared.log("Signing failed. No signature found.", .error)
                throw MusapError.internalError
            }
            
            return signature
            
        } catch {
            AppLogger.shared.log("Error with external sscd signing: \(error)", .error)
        }
        
        // If we got to here, some error happened
        throw MusapError.internalError
    }
    
    public func getSscdInfo() -> SscdInfo {
        let sscd = SscdInfo(sscdName: self.settings.getSscdName(),
                             sscdType: ExternalSscd.SSCD_TYPE,
                             sscdId: self.getSetting(forKey: "id"),
                             country: "FI",
                             provider: "MUSAP LINK",
                             keygenSupported: false,
                             algorithms: [KeyAlgorithm.RSA_2K],
                             formats: [SignatureFormat.RAW, SignatureFormat.CMS]
        )
        return sscd
    }
    
    public func isKeygenSupported() -> Bool {
        return false
    }
    
    public func getSettings() -> [String : String]? {
        return self.settings.getSettings()
    }
    
    public func getSettings() -> ExternalSscdSettings {
        return self.settings
    }
    
    
    /**
     Displays Enter MSISDN prompt for the user
     Usage:
     ExternalSscd.showEnterMsisdnDialog { msisdn in
         print("Received msisdn: \(msisdn)")
         // Handle the received msisdn
     }
     */
    private static func showEnterMsisdnDialog(completion: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene

            if let rootViewController = windowScene?.windows.first?.rootViewController {
                let msisdnInputView = MsisdnInputView { msisdn in
                    completion(msisdn)
                    rootViewController.dismiss(animated: true, completion: nil)
                }
                
                let hostingController = UIHostingController(rootView: msisdnInputView)

                hostingController.modalPresentationStyle = .fullScreen
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
        return UiccKeyAttestation(keyAttestationType: KeyAttestationType.UICC)
    }
    
    public func attestKey(key: MusapKey) -> KeyAttestationResult {
        return self.getKeyAttestation().getAttestationData(key: key)
    }
    
}
