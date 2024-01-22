//
//  MusapSscd.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public class MusapSscd: Codable, Identifiable {
    
    var sscdName:        String?
    var sscdType:        String?
    var sscdId:          String?
    var country:         String?
    var provider:        String?
    let keyGenSupported: Bool
    let algorithms:      [KeyAlgorithm]
    let formats:         [SignatureFormat]
    
    init(
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
