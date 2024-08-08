//
//  MusapKeyGenerator.swift
//
//
//  Created by Teemu Mänttäri on 2.4.2024.
//

import CryptoKit
import Security
import Foundation

public class MusapKeyGenerator: KeyGenerator {
    
    
    // Used in MSSP<->App communication
    public static let TRANSPORT_KEY_ALIAS = "transportkey"
    public static let MAC_KEY_ALIAS = "mackey"
    
    public static func hkdfStatic(_ useAes256: Bool) throws -> String {
        
        // Generate a random secret
        var key = Data(count: 16)
        let result = key.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(result))
        }
        
        // Derive keys using HKDF
        let salt = Data()
        let info = Data()
        let hkdfKey = SymmetricKey(data: key)
        let outputByteCount = 32 + (useAes256 ? 32 : 16)
        
        let derivedKeyData = HKDF<SHA256>.deriveKey(inputKeyMaterial: hkdfKey, salt: salt, info: info, outputByteCount: outputByteCount).withUnsafeBytes {
            Data($0)
        }
        
        let macKeyData = derivedKeyData.prefix(32)
        let encKeyData = derivedKeyData.suffix(useAes256 ? 32 : 16)
        
        print("MacKeyData b64: \(macKeyData.base64EncodedData())")
        print("transportKeyData b64: \(encKeyData.base64EncodedData())")

        
        // Try to store keys in keychain
        let storage = KeychainKeystorage()
        try storage.storeKey(keyName: MusapKeyGenerator.MAC_KEY_ALIAS, keyData: macKeyData)
        try storage.storeKey(keyName: MusapKeyGenerator.TRANSPORT_KEY_ALIAS, keyData: encKeyData)
        
        return key.base64EncodedString()
    }
    
    public static func hkdfStatic() throws -> String? {
        return try hkdfStatic(false)
    }
    
    
    public func hkdfStatic() throws -> String {
        return try MusapKeyGenerator.hkdfStatic(false)
    }
    
    public func hkdf() throws -> String {
        return try MusapKeyGenerator.hkdfStatic(false)
    }
    
}
