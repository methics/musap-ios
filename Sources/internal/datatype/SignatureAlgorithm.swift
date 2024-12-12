//
//  SignatureAlgorithm.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public class SignatureAlgorithm {
    
    public static let SHA256withECDSA  = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
    public static let SHA384withECDSA  = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA384
    public static let SHA512withECDSA  = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA512

    public static let SHA256withRSA    = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256
    public static let SHA384withRSA    = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA384
    public static let SHA512withRSA    = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA512

    public static let SHA256withRSAPSS = SecKeyAlgorithm.rsaSignatureMessagePSSSHA256
    public static let SHA384withRSAPSS = SecKeyAlgorithm.rsaSignatureMessagePSSSHA384
    public static let SHA512withRSAPSS = SecKeyAlgorithm.rsaSignatureMessagePSSSHA512
        
    private var algorithm: SecKeyAlgorithm?

    public init(algorithm: SecKeyAlgorithm?) {
        self.algorithm = algorithm
    }
    
    public func getAlgorithm() -> SecKeyAlgorithm? {
        return self.algorithm
    }
    
}
