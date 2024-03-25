//
//  SscdSettings.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public protocol SscdSettings {
    func getSetting(forKey key: String) -> String?
    func setSetting(key: String, value: String)
}

