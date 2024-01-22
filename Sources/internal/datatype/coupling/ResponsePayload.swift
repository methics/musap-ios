//
//  ResponsePayload.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.1.2024.
//

import Foundation

public class ResponsePayload: Decodable {
    
    public let status:    String
    public let errorCode: String?
    
    init(status: String, errorCode: String?) {
        self.status    = status
        self.errorCode = errorCode
    }
    
    func getErrorCode(errorCode: String?) -> Int? {
        guard let code = errorCode, let number = Int(code) else {
            return nil
        }
        return number
    }
    
}
