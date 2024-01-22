//
//  UpdateKeyReq.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 23.11.2023.
//

import Foundation

public class UpdateKeyReq {
    
    private let key:        MusapKey
    private let keyAlias:   String?
    private let did:        String?
    private let attributes: [KeyAttribute]?
    private let role:       String?
    private let state:      String?
    
    public init(key:        MusapKey,
         keyAlias:   String?,
         did:        String?,
         attributes: [KeyAttribute]?,
         role:       String?,
         state:      String?
    ) {
        self.key = key
        self.keyAlias = keyAlias
        self.did = did
        self.attributes = attributes
        self.role = role
        self.state = state
    }
    
    public func getKey() -> MusapKey {
        return self.key
    }
    
    public func getAlias() -> String? {
        return self.keyAlias
    }
    
    public func getDid() -> String? {
        return self.did
    }
    
    public func getAttributes() -> [KeyAttribute]? {
        return self.attributes
    }
    
    public func getRole() -> String? {
        return self.role
    }
    
    public func getState() -> String? {
        return self.state
    }
    
}
