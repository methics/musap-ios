//
//  LinkAccountPayload.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.1.2024.
//

import Foundation

public class LinkAccountPayload: Codable {
    
    public let couplingcode: String
    public let musapid:      String
    
    init(couplingcode: String, musapid: String) {
        self.couplingcode = couplingcode
        self.musapid = musapid
    }
    
    public func getBase64Encoded() -> String? {
        guard let jsonData = try? JSONEncoder().encode(self) else {
            return nil
        }
        return jsonData.base64EncodedString()
    }
    
    
}
