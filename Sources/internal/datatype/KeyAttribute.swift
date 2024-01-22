//
//  KeyAttribute.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public struct KeyAttribute: Codable {
    
    var name: String
    var value: String?
    
    init(name: String, value: String?) {
        self.name = name
        self.value = value
    }
}
