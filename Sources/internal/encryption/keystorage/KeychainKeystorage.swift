//
//  KeychainKeystorage.swift
//
//
//  Created by Teemu Mänttäri on 2.4.2024.
//

import Foundation

public class KeychainKeystorage: KeyStorage {
    
    public func storeKey(keyName: String, keyData: Data) throws {
        
        if keyExists(keyName: keyName) {
            do {
                try removeKey(keyName: keyName)
            } catch {
                throw MusapError.internalError
            }
        }
    
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
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyName.data(using: .utf8)!,
            kSecReturnData as String: true,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess {
            return (item as? Data)
        } else {
            return nil
        }
    }
    
    public func keyExists(keyName: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyName.data(using: .utf8),
            kSecReturnRef as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        return status == errSecSuccess
    }
    
    public func removeKey(keyName: String) throws {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyName.data(using: .utf8)!
        ]
        
        let status = SecItemDelete(deleteQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }
    
    
}
