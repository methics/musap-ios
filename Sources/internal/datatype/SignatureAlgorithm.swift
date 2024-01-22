//
//  SignatureAlgorithm.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public class SignatureAlgorithm {
    
    static let SHA256withECDSA  = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
    static let SHA384withECDSA  = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA384
    static let SHA512withECDSA  = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA512

    static let SHA256withRSA    = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256
    static let SHA384withRSA    = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA384
    static let SHA512withRSA    = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA512

    static let SHA256withRSAPSS = SecKeyAlgorithm.rsaSignatureMessagePSSSHA256
    static let SHA384withRSAPSS = SecKeyAlgorithm.rsaSignatureMessagePSSSHA384
    static let SHA512withRSAPSS = SecKeyAlgorithm.rsaSignatureMessagePSSSHA512
    
    //TODO: Support for NONEwithECDSA, NONEwithRSA, NONEwithRSASSA-PSS somehow
    
    private var algorithm: SecKeyAlgorithm?

    init(algorithm: SecKeyAlgorithm?) {
        self.algorithm = algorithm
    }
    
    public func getAlgorithm() -> SecKeyAlgorithm? {
        return self.algorithm
    }
    
}
