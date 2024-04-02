//
//  KeychainKeystorage.swift
//
//
//  Created by Teemu Mänttäri on 2.4.2024.
//

import Foundation

public class KeychainKeystorage: KeyStorage {
    public func storeKey(keyName: String, keyData: Data) throws {
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyName.data(using: .utf8)!,
            kSecValueData as String: keyData,
            kSecAttrKeySizeInBits as String: keyData.count * 8,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }
    
    public func loadKey(keyName: String) -> Data? {
        
    }
    
    public func keyExists(keyName: String) -> Bool {
        <#code#>
    }
    
    
}
