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
    
    func getKeyAttestation() -> KeyAttestationProtocol
    
    func attestKey(key: MusapKey) -> KeyAttestationResult
    
}

extension MusapSscdProtocol {
    func isKeyGenSupported() -> Bool {
        return self.getSscdInfo().isKeygenSupported()
    }
    
    func getKeyAttestation() -> KeyAttestationProtocol {
        return NoKeyAttestation()
    }
    
    func attestKey(key: MusapKey) -> KeyAttestationResult {
        return self.getKeyAttestation().getAttestationData(key: key)
    }
    
    
}
