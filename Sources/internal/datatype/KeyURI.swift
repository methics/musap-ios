//
//  KeyURI.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 6.11.2023.
//

import Foundation

public class KeyURI: Codable, Equatable, Hashable {
    
    public static let NAME    = "name"
    public static let LOA     = "loa"
    public static let COUNTRY = "country"
    public static let SSCD    = "sscd"
    
    private var keyUriMap: [String: String] = [:]
    
    
    public init(name: String?, sscd: String?, loa: String?) {
        if name != nil { self.keyUriMap["name"] = name }
        if sscd != nil { self.keyUriMap["sscd"] = sscd }
        if loa  != nil { self.keyUriMap["loa"]  = loa  }
    }
    
    public init(keyUri: String) {
        self.keyUriMap = self.parseUri(keyUri)
    }
    
    public init(key: MusapKey) {
        if key.getKeyAlias()    != nil { keyUriMap["alias"]      = key.getKeyAlias()                            }
        if key.getAlgorithm()   != nil { keyUriMap["algorithm"]  = (key.getAlgorithm()?.isEc())! ? "EC" : "RSA" }
        if key.getCreatedDate() != nil { keyUriMap["created_dt"] = key.getCreatedDate()?.ISO8601Format()        }
        
        if key.getAttributeValue(attrName: "msisdn") != nil { keyUriMap["msisdn"] = key.getAttributeValue(attrName: "msisdn") }
        if key.getAttributeValue(attrName: "serial") != nil { keyUriMap["serial"] = key.getAttributeValue(attrName: "serial")}
        
        if key.getSscdInfo() != nil {
            let sscdName = key.getSscdInfo()?.getSscdName()
            let sscdCountry = key.getSscdInfo()?.getCountry()
            let sscdProvider = key.getSscdInfo()?.getProvider()
            
            if sscdName     != nil  { keyUriMap["sscd"]     = sscdName     }
            if sscdCountry  != nil  { keyUriMap["country"]  = sscdCountry  }
            if sscdProvider != nil  { keyUriMap["provider"] = sscdProvider }
        }
    }
    
    
    private func parseUri(_ keyUri: String) -> [String: String] {
        var keyUriMap = [String: String]()
        print("Parsing KeyURI: \(keyUri)")

        guard let commaIndex = keyUri.firstIndex(of: ",") else {
            return keyUriMap
        }

        let parts = keyUri.replacingOccurrences(of: "mss:", with: "").components(separatedBy: ",")

        for attribute in parts {
            if attribute.contains("=") {
                let split = attribute.components(separatedBy: "=")
                guard split.count >= 2 else { continue }

                let key = split[0]
                let value = split[1]
                print("Parsed \(key)=\(value)")
                keyUriMap[key] = value
            } else {
                print("Ignoring invalid attribute \(attribute)")
            }
        }
        print("parsed KeyURI to: \(keyUriMap)")
    
        return keyUriMap
    }
    
    public func getUri() -> String {
        var components = [String]()
        for (key, value) in self.keyUriMap {
            components.append("\(key)=\(value)")
        }
        return "mss:" + components.joined(separator: ",")
    }
    
    public static func == (lhs: KeyURI, rhs: KeyURI) -> Bool {
        return lhs.keyUriMap == rhs.keyUriMap
    }
    
    public func keyUriMatches(keyUri: KeyURI) -> Bool {
        return self == keyUri
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(keyUriMap)
    }
    
}
