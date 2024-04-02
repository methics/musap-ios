//
//  KeyStorage.swift
//
//
//  Created by Teemu Mänttäri on 2.4.2024.
//

import Foundation

public protocol KeyStorage {
    
    func storeKey(keyName: String, keyData: Data) throws -> Void
    func loadKey(keyName: String) -> Data?
    func keyExists(keyName: String) -> Bool
    
}

