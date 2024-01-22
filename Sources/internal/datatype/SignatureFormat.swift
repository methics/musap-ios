//
//  SignatureFormat.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation


public class SignatureFormat: Codable {
    
    public static let CMS = SignatureFormat("CMS")
    public static let RAW = SignatureFormat("RAW") // PKCS1
    
    private var format: String;
    
    init(_ format: String) {
        self.format = format
    }
    
    public func getFormat() -> String {
        return self.format
    }
    
    public static func fromString(format: String) -> SignatureFormat {
        switch format.uppercased() {
        case "CMS":
            return SignatureFormat.CMS
        case "RAW":
            return SignatureFormat.RAW
        default:
            return SignatureFormat.RAW
        }
    }
    
    
}
