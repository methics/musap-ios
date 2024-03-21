//
//  SscdSearchReq.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.11.2023.
//

import Foundation

public class SscdSearchReq {
    
    var sscdType:  String?
    var country:   String?
    var provider:  String?
    var sscdId:    String?
    var algorithm: KeyAlgorithm?
    
    public init(
        sscdType:  String? = nil,
        country:   String? = nil,
        provider:  String? = nil,
        sscdId:    String? = nil,
        algorithm: KeyAlgorithm? = nil
    ) {
        self.sscdType = sscdType
        self.country = country
        self.provider = provider
        self.sscdId = sscdId
        self.algorithm = algorithm
    }
    
    /**
    Check if given SSCD matches this search request
     */
    public func matches(sscd: SscdInfo) -> Bool {
        // Null check with if let
        if let algorithm = self.algorithm,
           let country = self.country,
           let provider = self.provider,
           let sscdType = self.sscdType
        {
            // Compare
            if !sscd.getSupportedAlgorithms().contains(algorithm) { return false }
            if country  != sscd.getCountry()   { return false }
            if provider != sscd.getProvider() { return false }
            if sscdType != sscd.getSscdType() { return false }
        } else {
            //TODO: Is this supposed to be 1:1 match or is partial match accepted?
            return false
        }
        
        return true
        
    }
    
}
