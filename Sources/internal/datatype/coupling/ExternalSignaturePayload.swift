//
//  ExternalSignaturePayload.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.1.2024.
//

import Foundation


public class ExternalSignaturePayload: Codable {
    
    public var clientid: String?
    public var sscdName: String?
    public var data:     String?
    public var display:  String?
    public var format:   String?
    public var publickey: String?
    public var timeout: String?
    public var transid: String?
    public var attributes: [String:String]?
    public var keyid: String?
    public var keyusages: [String]?
    
    
    init(clientid: String) {
        self.clientid = clientid
    }
    
    init(){}
    
    public func getBase64Encoded() -> String? {
        guard let jsonData = try? JSONEncoder().encode(self) else {
            return nil
        }
        
        return jsonData.base64EncodedString()
    }
}
