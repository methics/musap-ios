//
//  KeyGenReq.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public class KeyGenReq {
    
    public let keyAlias:     String
    public let did:          String?
    public let role:         String
    public let stepUpPolicy: StepUpPolicy?
    public let attributes:   [KeyAttribute]?
    public let keyAlgorithm: KeyAlgorithm?
    
    public init(
        keyAlias:     String,
        did:          String? = nil,
        role:         String,
        stepUpPolicy: StepUpPolicy? = nil,
        attributes:   [KeyAttribute]? = nil,
        keyAlgorithm: KeyAlgorithm? = nil
    )
    {
        self.keyAlias     = keyAlias
        self.did          = did
        self.role         = role
        self.stepUpPolicy = stepUpPolicy
        self.attributes   = attributes
        self.keyAlgorithm = keyAlgorithm
    }
    
}
