//
//  MockKeyStorage.swift
//
//
//  Created by Teemu Mänttäri on 12.4.2024.
//

import Foundation
import musap_ios

public class MockKeyStorage: KeyStorage {
    
    
    var keys: [String: Data] = [:]
    
    public func storeKey(keyName: String, keyData: Data) throws {
        self.keys[keyName] = keyData
    }
    
    public func loadKey(keyName: String) -> Data? {
        return self.keys[keyName]
    }
    
    public func keyExists(keyName: String) -> Bool {
        if self.keys[keyName] != nil { return true }
        return false
    }
    
    
}
