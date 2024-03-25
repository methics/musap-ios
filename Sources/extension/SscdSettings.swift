//
//  SscdSettings.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public protocol SscdSettings {
    
    func getSettings() -> [String:String]?
    
    func getSetting(forKey key: String) -> String?
    
}

public extension SscdSettings {
    
    func getSetting(forKey key: String) -> String? {
        
        guard let settings = getSettings() else {
            print("Getting setting failed, self.getSettings() was nil")
            return nil
        }
        
        return settings[key]
    }
    
    func setSetting(key: String, value: String) -> Void {
        print("setSetting: \(key) = \(value)")
        if (self.getSettings() == nil) {
            print("self.getSettings() was nil, return")
            return
        }
        guard var settings = self.getSettings() else {
            return
        }
        
        settings[key] = value
        print("Setting is set!")
    }
    
}
