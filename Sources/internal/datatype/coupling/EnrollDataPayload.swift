//
//  EnrollDataPayload.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.1.2024.
//

import Foundation

class EnrollDataPayload: Codable {
    
    private let apnsToken: String?
    private let secret: String
    
    public init(apnsToken: String?, secret: String) {
        self.apnsToken = apnsToken
        self.secret = secret
    }
    
    public func getBase64Encoded() -> String? {
        guard let jsonData = try? JSONEncoder().encode(self) else {
            return nil
        }
        return jsonData.base64EncodedString()
    }
    
}
