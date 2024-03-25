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
        print("SecureEnclaveSettings.setSetting: \(key) value: \(value)")
        self.settings[key] = value
        
        if self.settings[key] != value {
            print("Settings were saved incorrectly.")
        }
    }
    
}
