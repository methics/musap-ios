//
//  EnrollDataPayload.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.1.2024.
//

import Foundation

class EnrollDataPayload: Codable {
    
    private let apnstoken: String?
    private let tokendata: String?
    
    
    public class TokenData: Codable {
        private let secret: String
        
        public init(secret: String) {
            self.secret = secret
        }
        
        public func getBase64Encoded() -> String? {
            guard let jsonData = try? JSONEncoder().encode(self) else {
                return nil
            }
            return jsonData.base64EncodedString()
        }
    }
    
    public init(apnstoken: String?, secret: String) {
        self.apnstoken = apnstoken
        self.tokendata = TokenData(secret: secret).getBase64Encoded()
    }
    
    public func getBase64Encoded() -> String? {
        guard let jsonData = try? JSONEncoder().encode(self) else {
            return nil
        }
        return jsonData.base64EncodedString()
    }
    
}
