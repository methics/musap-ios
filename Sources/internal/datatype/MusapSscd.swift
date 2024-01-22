//
//  MusapSscd.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public class MusapSscd: Codable, Identifiable {
    
    public var sscdName:        String?
    public var sscdType:        String?
    public var sscdId:          String?
    public var country:         String?
    public var provider:        String?
    public let keyGenSupported: Bool
    public let algorithms:      [KeyAlgorithm]
    public let formats:         [SignatureFormat]
    
    public init(
        sscdName: String,
        sscdType: String,
        sscdId: String,
        country: String,
        provider: String,
        keyGenSupported: Bool,
        algorithms: [KeyAlgorithm],
        formats: [SignatureFormat]
    )
    {
        self.sscdName        = sscdName
        self.sscdType        = sscdType
        self.sscdId          = sscdId
        self.country         = country
        self.provider        = provider
        self.keyGenSupported = keyGenSupported
        self.algorithms      = algorithms
        self.formats         = formats
    }
    
}
