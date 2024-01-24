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
    
    public init(settings: ExternalSscdSettings, clientid: String, musapLink: MusapLink) {
        self.settings = settings
        self.clientid = settings.getClientId() ?? "LOCAL"
        self.musapLink = settings.getMusapLink()! //TODO: Dont use !
    }
    
    public func bindKey(req: KeyBindReq) throws -> MusapKey {
        print("ExternalSscd.bindKey() started")
        let request: ExternalSignaturePayload = ExternalSignaturePayload(clientid: self.clientid)
        
        var theMsisdn: String? = nil
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
                    
                    
                    
                    // Send signature?
                    let musapSignature = MusapSignature(rawSignature: signatureData)
                    
                    MusapClient.sendSignatureCallback(signature: musapSignature, txnId: response.transid)
                    
                    guard let publickey = response.publickey else {
                        print("ExternalSscd.bindKey(): No Public Key")
                        return
                    }
            
                    guard let publicKeyData = publickey.data(using: .utf8) else {
                        print("could not turn publick ey string to data")
                        return
                    }
                    
                    theKey =  MusapKey(
                        keyAlias:  req.getKeyAlias(),
                        sscdType:  ExternalSscd.SSCD_TYPE,
                        publicKey: PublicKey(publicKey: publicKeyData),
                        algorithm: KeyAlgorithm.RSA_2K,  //TODO: resolve this
                        keyUri:    KeyURI(name: req.getKeyAlias(),
                                          sscd: ExternalSscd.SSCD_TYPE,
                                          loa: "loa2"
                                         ) //TODO: What LoA?
                    )
                    theKey?.addAttribute(attr: KeyAttribute(name: ExternalSscd.ATTRIBUTE_MSISDN, value: theMsisdn))
                    
                    
                    
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
        
        request.attributes?[ExternalSscd.ATTRIBUTE_MSISDN] = theMsisdn
        request.clientid = self.clientid
        request.display  = req.getDisplayText()
        request.format   = req.getFormat().getFormat()
        request.data     = dataBase64
        
        print("ExternalSscd.sign() attributes: \(String(describing: request.attributes))")
        
        if request.attributes == nil {
            request.attributes = [String: String]()
        }
        
        request.attributes?[ExternalSscd.ATTRIBUTE_MSISDN] = theMsisdn
        
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
                    
                    theSignature = MusapSignature(rawSignature: rawSignature)
                    
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
    
    public func getSscdInfo() -> MusapSscd {
        let sscd = MusapSscd(sscdName: self.settings.getSscdName(),
                             sscdType: ExternalSscd.SSCD_TYPE,
                             sscdId: "", //TODO: Fix
                             country: "FI",
                             provider: "MUSAP LINK",
                             keyGenSupported: false,
                             algorithms: [KeyAlgorithm.RSA_2K],
                             formats: [SignatureFormat.RAW, SignatureFormat.CMS]
        )
        return sscd
    }
    
    public func generateSscdId(key: MusapKey) -> String {
        return ExternalSscd.SSCD_TYPE + "/" + (key.getAttributeValue(attrName: ExternalSscd.ATTRIBUTE_MSISDN) ?? "")
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
}
