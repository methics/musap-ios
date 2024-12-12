//
//  KeySearchReq.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.11.2023.
//

import Foundation

public class KeySearchReq {
    
    private let sscdType:     String?
    private let country:      String?
    private let provider:     String?
    private let keyAlgorithm: KeyAlgorithm?
    private let keyUri:       String?
    
    
    public init(
         sscdType:     String?       = nil,
         country:      String?       = nil,
         provider:     String?       = nil,
         keyAlgorithm: KeyAlgorithm? = nil,
         keyUri:       String?       = nil
    ) {
        self.sscdType     = sscdType
        self.country      = country
        self.provider     = provider
        self.keyAlgorithm = keyAlgorithm
        self.keyUri       = keyUri
    }
    
    public func getSscdType() -> String? {
        return self.sscdType
    }
    
    public func getCountry() -> String? {
        return self.country
    }
    
    public func getProvider() -> String? {
        return self.provider
    }
    
    public func getKeyAlgorithm() -> KeyAlgorithm? {
        return self.keyAlgorithm
    }
    
    public func keyMatches(key: MusapKey) -> Bool {
        if ((self.keyAlgorithm == nil) != (key.getAlgorithm() != nil)) { return false }
        guard let currentKeyUri = self.keyUri else {
            print("Current key uri is nil")
            //Throw?
            return false
        }
        let keyUriObj = KeyURI(keyUri: currentKeyUri)
        
        if keyUriObj == key.getKeyUri() {
            //TODO: What else to compare?
            return true
        }
        
        return true
    }
    
}
