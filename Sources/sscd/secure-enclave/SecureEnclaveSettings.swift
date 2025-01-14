//
//  SecureEnclaveSettings.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 6.11.2023.
//

import Foundation

public class SecureEnclaveSettings: SscdSettings {

    
    private var settings: [String: String] = [:]
    
    public init() {
    }
    
    public func getSettings() -> [String : String]? {
        return self.settings
    }
    
    public func setSetting(key: String, value: String) {
        AppLogger.shared.log("setSetting for: \(key): \(value)")
        self.settings[key] = value
        
        if self.settings[key] != value {
            AppLogger.shared.log("Failed to save settings")
            // Throw?
        }
    }
    
    public func getSetting(forKey key: String) -> String? {
        return settings[key]
    }
    
}
