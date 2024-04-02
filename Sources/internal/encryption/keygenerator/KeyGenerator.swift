//
//  File.swift
//  
//
//  Created by Teemu Mänttäri on 2.4.2024.
//

import Foundation

public protocol KeyGenerator {
    
    func hkdf() throws -> String
}
