//
//  SscdSettings.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

protocol SscdSettings {
    
    func getSettings() -> [String:String]?
    
    func getSetting(forKey key: String) -> String?
    
}

extension SscdSettings {
    
    func getSetting(forKey key: String) -> String? {
        
        guard let settings = getSettings() else {
            return nil
        }
        
        return settings[key]
    }
    
    func setSetting(key: String, value: String) -> Void {
        if (self.getSettings() == nil) { return }
        guard var settings = self.getSettings() else {
            return
        }
        settings[key] = value
    }
    
}
