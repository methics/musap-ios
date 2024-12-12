//
//  PollResponsePayload.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.1.2024.
//

import Foundation

public class PollResponsePayload: ResponsePayload {
    
    public static let MODE_SIGN    = "sign"
    public static let MODE_GENSIGN = "generate-sign"
    public static let MODE_GENONLY = "generate-only"
    
    private let signaturePayload: SignaturePayload
    private var transId: String
    
    init(signaturePayload: SignaturePayload, transId: String, status: String?, errorCode: String?) {
        self.signaturePayload = signaturePayload
        self.transId = transId
        super.init(status: status ?? "", errorCode: errorCode)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    public func toSignatureReq(key: MusapKey) -> SignatureReq? {
        guard let req = self.signaturePayload.toSignatureReq(key: key) else {
            print("toSignatureReq failed")
            return nil
        }

        print("PollResponsePayload: setting transid to \(self.transId)")
        req.setTransId(transId: self.transId)
        
        return req
    }
    
    public func toKeygenReq() -> KeyGenReq? {
        guard let keyGenReq = self.signaturePayload.toKeygenReq() else {
            return nil
        }
        
        return keyGenReq
    }
    
    public func getSignaturePayload() -> SignaturePayload {
        return self.signaturePayload
    }
    
    public func getDisplayText() -> String {
        return self.signaturePayload.display
    }
    
    public func getMode() -> String {
        return self.signaturePayload.mode ?? PollResponsePayload.MODE_SIGN
    }
    
    public func shouldGenerateKey() -> Bool {
        return PollResponsePayload.MODE_SIGN != self.getMode()
    }
    
    public func shouldSign() -> Bool {
        return PollResponsePayload.MODE_GENONLY != self.getMode()
    }
    
    public func getTransId() -> String? {
        return self.transId
    }
    
    public func setTransId(transId: String) {
        self.transId = transId
    }
    
}
