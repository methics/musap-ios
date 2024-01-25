//
//  File.swift
//  
//
//  Created by Teemu Mänttäri on 25.1.2024.
//

import Foundation

public class KeygenCallbackTask {
    
    func runTask(link: MusapLink, key: MusapKey, txnId: String) throws {
        
        do {
            try link.sendKeygenCallback(key: key, txnId: txnId)
        } catch {
            print("KeygenCallbackTask error: \(error)")
            throw MusapError.internalError
        }
    }
    
}
