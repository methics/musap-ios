//
//  File.swift
//  
//
//  Created by Teemu Mänttäri on 20.3.2024.
//

import Foundation

public class SscdInfo: Encodable, Decodable {
    
    private var sscdName: String
    private var sscdType: String
    private var sscdId:   String
    private var country:  String
    private var provider: String
    private var keygenSupported: Bool
    private var algorithms: [KeyAlgorithm]
    private var formats:    [SignatureFormat]
    
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
    
    public func setSscdId(sscdId: String) -> Void {
        self.sscdId = sscdId
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
