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
    private let transId: String
    
    init(signaturePayload: SignaturePayload, transId: String, status: String?, errorCode: String?) {
        self.signaturePayload = signaturePayload
        self.transId = transId
        super.init(status: status ?? "", errorCode: errorCode)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
        //TODO: PollResponsePayload is not created with json decoder, so this will definitely fatalError if it is done later on
        // See MusapLink.poll() return PollResponsePayload()
    }
    
    public func toSignatureReq(key: MusapKey) -> SignatureReq? {
        guard let req = self.signaturePayload.toSignatureReq(key: key) else {
            print("toSignatureReq failed")
            return nil
        }

        req.setTransId(transId: self.transId)
        
        guard req != nil else {
            return nil
        }
        
        return req
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
    
}
