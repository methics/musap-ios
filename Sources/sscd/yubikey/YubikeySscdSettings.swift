//
//  YubikeySscdSettings.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 22.11.2023.
//

import Foundation

public class YubikeySscdSettings: SscdSettings {
    
    private var settings: [String: String] = [:]
    
    public init() {}
    
    public func getSettings() -> [String : String]? {
        return settings
    }
    
    public func setSetting(key: String, value: String) {
        self.settings[key] = value
    }
    
    public func getSetting(forKey key: String) -> String? {
        return self.settings[key]
    }
    
    
}
