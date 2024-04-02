//
//  ExternalSignatureResponsePayload.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.1.2024.
//

import Foundation

public class ExternalSignatureResponsePayload: ResponsePayload {
    let signature: String?
    let publickey: String?
    let certificate: String?
    let certificateChain: [String]?
    
    let transid: String
    let attributes: [String: String]?
    
    init(signature: String?,
         publickey: String,
         certificate: String,
         certificateChain: [String],
         transid: String,
         attributes: [String : String],
         status: String,
         errorCode: String?
    ) {
        self.signature = signature
        self.publickey = publickey
        self.certificate = certificate
        self.certificateChain = certificateChain
        self.transid = transid
        self.attributes = attributes
        super.init(status: status, errorCode: errorCode)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode each property
        signature = try container.decodeIfPresent(String.self, forKey: .signature)
        publickey = try container.decodeIfPresent(String.self, forKey: .publicKey)
        certificate = try container.decodeIfPresent(String.self, forKey: .certificate)
        certificateChain = try container.decodeIfPresent([String].self, forKey: .certificateChain)
        transid = try container.decode(String.self, forKey: .transid)
        attributes = try container.decodeIfPresent([String: String].self, forKey: .attributes)
        
        // Call the superclass initializer
        let status = try container.decode(String.self, forKey: .status)
        let errorCode = try container.decodeIfPresent(String.self, forKey: .errorCode)
        super.init(status: status, errorCode: errorCode)
    }
    
    public func isSuccess() -> Bool {
        return self.status.lowercased() == "success"
    }
    
    public func getRawSignature() -> Data? {
        if (self.signature == nil) { return nil }
        return signature?.data(using: .utf8)
    }
    
    public func getPublicKey() -> String? {
        return self.publickey
    }
    
    public func getCertificate() -> String? {
        return self.certificate
    }
    
    private enum CodingKeys: String, CodingKey {
        case signature, publicKey = "publickey", certificate, certificateChain = "certificate_chain", transid = "transid", attributes, status, errorCode = "errorcode"
    }
}
