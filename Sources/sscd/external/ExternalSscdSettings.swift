//
//  ExternalSscdSettings.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 5.1.2024.
//

import Foundation

public class ExternalSscdSettings: SscdSettings {
    
    public static let SETTINGS_TIMEOUT   = "timeout"
    public static let SETTINGS_CLIENT_ID = "clientid"
    public static let SETTINGS_SSCD_NAME = "sscdname"
    
    private var settings: [String: String] = [:]
    private var timeout: TimeInterval
    
    init(clientId: String) {
        self.timeout = 2 * 60
        settings[ExternalSscdSettings.SETTINGS_TIMEOUT]   = String(self.timeout * 1000)
        settings[ExternalSscdSettings.SETTINGS_CLIENT_ID] = clientId
    }
    
    public func setSscdName(name: String) {
        self.setSetting(key: ExternalSscdSettings.SETTINGS_SSCD_NAME, value: name)
    }
    
    public func getSscdName() -> String {
        guard let name = self.getSetting(forKey: ExternalSscdSettings.SETTINGS_SSCD_NAME) else {
            return "External Signature"
        }
        return name
    }
    
    public func getTimeout() -> TimeInterval {
        return self.timeout
    }
    
    public func getClientId() -> String? {
        guard let clientId = self.getSetting(forKey: ExternalSscdSettings.SETTINGS_CLIENT_ID) else {
            return nil
        }
        return clientId
    }
    
    public func getSettings() -> [String : String]? {
        return ["": ""]
    }
    
    public func getMusapLink() -> MusapLink? {
        return MusapClient.getMusapLink()
    }
    
    
    
}
