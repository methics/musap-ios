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
        print("Binding ExternalSscd")
        
        let request: ExternalSignaturePayload = ExternalSignaturePayload(clientid: self.clientid)
        
        var theMsisdn: String? = nil
        let msisdn = req.getAttribute(name: ExternalSscd.ATTRIBUTE_MSISDN)
        
        let semaphore = DispatchSemaphore(value: 0)
        if msisdn == nil {
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
            throw MusapError.internalError
        }
        
        request.data     = base64Data
        request.clientid = self.clientid
        request.display  = req.getDisplayText()
        request.format   = "RAW"

        if request.attributes == nil {
            request.attributes = [String: String]()
        }
        
        request.attributes?[ExternalSscd.ATTRIBUTE_MSISDN] = theMsisdn
        
        do {
            var theKey: MusapKey?
            
            let signSemaphore = DispatchSemaphore(value: 0)
            self.musapLink.sign(payload: request) { result in
                
                switch result {
                case .success(let response):
                    
                    guard let signature = response.signature else {
                        print("no signature")
                        return
                    }
                            
                    guard let signatureData = signature.data(using: .utf8) else {
                        print("Can't turn string to data")
                        return
                    }
                                         
                    guard let publickey = response.publickey else {
                        print("ExternalSscd.bindKey(): No Public Key")
                        return
                    }
                    
                    guard let certStr = response.certificate,
                          let certData = Data(base64Encoded: certStr),
                          let secCertificate = SecCertificateCreateWithData(nil, certData as CFData)
                    else
                    {
                        print("No certificate in result")
                        return
                    }
                    
                    guard let certificateChain = response.certificateChain else {
                        print("No certificate chain in result")
                        return
                    }
                    
                    var musapCertChain: [MusapCertificate] = [MusapCertificate]()
                    
                    for cert in certificateChain {

                        guard let certData = Data(base64Encoded: cert),
                              let secCert = SecCertificateCreateWithData(nil, certData as CFData)
                        else 
                        {
                            print("Could not create SecCertificate from certificateB64")
                            return
                        }
                        
                        guard let newMusapCert = MusapCertificate(cert: secCert) else {
                            print("Failed to generate MusapCertificate()")
                            return
                        }
                        
                        musapCertChain.append(newMusapCert)
                    }
                    
                    self.attestationSecCertificate = secCertificate
            
                    guard let publicKeyData = Data(base64Encoded: publickey) else {
                        print("Invalid base64 encoded public key")
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
                    print("bindKey()->musapLink->sign() error while binding key: \(error)")
    
                }
                signSemaphore.signal()
            }
            signSemaphore.wait()
        
            guard let musapKey = theKey else {
                print("ExternalSscd.bindKey() - ERROR: No MUSAP KEY")
                throw MusapError.internalError
            }
            
            let keyUri = KeyURI(key: musapKey)
            musapKey.setKeyUri(value: keyUri)
            musapKey.addAttribute(attr: KeyAttribute(name: ExternalSscd.ATTRIBUTE_MSISDN, value: theMsisdn))
            
            
            guard let attestationCert = self.attestationSecCertificate else {
                print("no attestation cert")
                throw MusapError.internalError
            }
            
            let attestAttr = KeyAttribute(name: "ATTEST", cert: attestationCert)
            musapKey.addAttribute(attr: attestAttr)
            return musapKey

        } catch {
            print("error: \(error)")
        }
        
        // If we get to here, some error happened
        throw MusapError.internalError
    }
    
    public func generateKey(req: KeyGenReq) throws -> MusapKey {
        fatalError("Unsupported Operation")
    }
    
    public func sign(req: SignatureReq) throws -> MusapSignature {
        let request = ExternalSignaturePayload(clientid: self.clientid)
        
        var theMsisdn: String? = nil // Eventually this gets set into the attributes
        let msisdn = req.getAttribute(name: ExternalSscd.ATTRIBUTE_MSISDN)
        
        let semaphore = DispatchSemaphore(value: 0)
        if msisdn == nil {
            ExternalSscd.showEnterMsisdnDialog { msisdn in
                print("Received MSISDN: \(msisdn)")
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
        
        print("ExternalSscd.sign() attributes: \(String(describing: request.attributes))")
               
        do {
            var theSignature: MusapSignature?
            
            let signSemaphore = DispatchSemaphore(value: 0)
            self.musapLink.sign(payload: request) { result in
                
                switch result {
                case .success(let response):
                    print("Got success: \(response.isSuccess())")
                    guard let rawSignature = response.getRawSignature() else {
                        return
                    }

                    theSignature = MusapSignature(rawSignature: rawSignature, key: req.getKey(), algorithm: req.algorithm, format: req.format)
                    
                case .failure(let error):
                    print("an error occured: \(error)")
                }
                
                signSemaphore.signal()
                
            }
            
            signSemaphore.wait()
            guard let signature = theSignature else {
                throw MusapError.internalError
            }
            
            return signature
            
        } catch {
            print("error in ExternalSscd.sign(): \(error)")
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
