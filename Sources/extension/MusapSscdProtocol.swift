//
//  MusapSscdProtocol.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public protocol MusapSscdProtocol: SscdSettings {
    
    associatedtype CustomSscdSettings: SscdSettings
    
    func bindKey(req: KeyBindReq) throws -> MusapKey
    
    func generateKey(req: KeyGenReq) throws -> MusapKey
    
    func sign(req: SignatureReq) throws -> MusapSignature
    
    func getSscdInfo() -> SscdInfo
    
    func isKeygenSupported() -> Bool
    
    func getSettings() -> CustomSscdSettings
    
}

extension MusapSscdProtocol {
    func isKeyGenSupported() -> Bool {
        return self.getSscdInfo().isKeygenSupported()
    }
}
