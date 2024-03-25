//
//  SscdSettings.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public protocol SscdSettings {
    var settings: [String: String] { get set }

    func getSetting(forKey key: String) -> String?
    func setSetting(key: String, value: String)
}

public extension SscdSettings {
    func getSetting(forKey key: String) -> String? {
        return settings[key]
    }

    mutating func setSetting(key: String, value: String) {
        settings[key] = value
    }
}
