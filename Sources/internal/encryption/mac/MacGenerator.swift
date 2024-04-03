//
//  MacGenerator.swift
//  
//
//  Created by Teemu Mänttäri on 3.4.2024.
//

import Foundation

public protocol MacGenerator {
    
    func generate(message: String, iv: String, transId: String?, type: String) throws -> String
    func validate(message: String, iv: String, transId: String?, type: String, mac: String) throws -> Bool
    
}
