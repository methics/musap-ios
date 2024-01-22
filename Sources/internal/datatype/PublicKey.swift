//
//  PublicKey.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation
import YubiKit

public class PublicKey: Codable {
    
    private var publickeyDer: Data

    public init(publicKey: Data) {
        self.publickeyDer = publicKey
    }

    public func getDER() -> Data {
        return publickeyDer
    }

    public func getPEM() -> String {
        let base64Signature = publickeyDer.base64EncodedString()

        var pem = "-----BEGIN PUBLIC KEY-----\n"

        let width = 64
        let length = base64Signature.count

        for i in stride(from: 0, to: length, by: width) {
            let end = min(i + width, length)
            let range = base64Signature.index(base64Signature.startIndex, offsetBy: i)..<base64Signature.index(base64Signature.startIndex, offsetBy: end)
            pem += base64Signature[range]
            pem += "\n"
        }

        pem += "-----END PUBLIC KEY-----\n"
        return pem
    }
    
    //TODO: Do we even need this?
    public func toSecKey(keyType: String) -> SecKey? {
        let keyData = publickeyDer
        
        var attributes: [String: Any] = [
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic
        ]
        
        if keyType.lowercased() == "ec" {
            attributes[kSecAttrKeyType as String] = kSecAttrKeyTypeEC
        } else if keyType.lowercased() == "rsa" {
            attributes[kSecAttrKeyType as String] = kSecAttrKeyTypeRSA
        } else {
            print("Unsupported key type")
            return nil
        }
        
        
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            print("error creating SecKey: \(error!.takeRetainedValue())")
            return nil
        }
        
        return secKey
    }
    
    public func toSecKey(keyType: YKFPIVKeyType) -> SecKey? {
        let keyData = publickeyDer
        
        var attributes: [String: Any] = [
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic
        ]
        
        switch keyType {
        case .ECCP256:
            attributes[kSecAttrKeyType as String] = kSecAttrKeyTypeECSECPrimeRandom
            attributes[kSecAttrKeySizeInBits as String] = 256
        case .ECCP384:
            attributes[kSecAttrKeyType as String] = kSecAttrKeyTypeECSECPrimeRandom
            attributes[kSecAttrKeySizeInBits as String] = 384
        case .RSA1024:
            attributes[kSecAttrKeyType as String] = kSecAttrKeyTypeRSA
            attributes[kSecAttrKeySizeInBits as String] = 1024
        case .RSA2048:
            attributes[kSecAttrKeyType as String] = kSecAttrKeyTypeRSA
            attributes[kSecAttrKeySizeInBits as String] = 2048

        default:
            return nil
        }
        
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            print("error creating SecKey: \(error!.takeRetainedValue())")
            return nil
        }
        
        return secKey
        
    }
}
