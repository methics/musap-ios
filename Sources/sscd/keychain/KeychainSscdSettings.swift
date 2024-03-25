//
//  KeychainSscdSettings.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 14.11.2023.
//

import Foundation

public class KeychainSscdSettings: SscdSettings {
    
    private var settings: [String: String] = [:]
    
    public init() {}
    
    public func getSettings() -> [String : String]? {
        return settings
    }
    
    public func getSetting(forKey key: String) -> String? {
        return settings[key]
    }
    
    public func setSetting(key: String, value: String) {
        self.settings[key] = value
    }
    
    
}
