//
//  File.swift
//  
//
//  Created by Teemu Mänttäri on 20.3.2024.
//

import Foundation

public class SscdInfo {
    
    private let sscdName: String
    private let sscdType: String
    private let sscdId:   String
    private let country:  String
    private let provider: String
    private let keygenSupported: Bool
    private let algorithms: [KeyAlgorithm]
    private let formats:    [SignatureFormat]
    
    public init(
        sscdName: String,
        sscdType: String,
        sscdId: String,
        country: String,
        provider: String,
        keygenSupported: Bool,
        algorithms: [KeyAlgorithm],
        formats: [SignatureFormat]
    ) {
        self.sscdName = sscdName
        self.sscdType = sscdType
        self.sscdId = sscdId
        self.country = country
        self.provider = provider
        self.keygenSupported = keygenSupported
        self.algorithms = algorithms
        self.formats = formats
    }
    
    public func getSscdName() -> String {
        return self.sscdName
    }
    
    public func getSscdType() -> String {
        return self.sscdType
    }
    
    public func getSscdId() -> String {
        return self.sscdId
    }
    
    public func getCountry() -> String {
        return self.country
    }
    
    public func getProvider() -> String {
        return self.provider
    }
    
    public func isKeygenSupported() -> Bool {
        return self.keygenSupported
    }
    
    public func getSupportedAlgorithms() -> [KeyAlgorithm] {
        return self.algorithms
    }
    
}
