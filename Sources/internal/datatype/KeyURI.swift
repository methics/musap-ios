//
//  KeyURI.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 6.11.2023.
//

import Foundation

public class KeyURI: Codable, Equatable, Hashable {
    

    public static let SSCD = "sscd" // SSCD type e.g. "sim"
    public static let PROVIDER = "provider" // Key provider. For example MNO brand name "DNA"
    public static let COUNTRY = "country"
    public static let IDENTITY_SCHEME = "identity-scheme" // E.g. NIST or eIDAS
    public static let SERIAL = "serial"
    public static let MSISDN = "msisdn"
    public static let LOA = "loa" // e.g. "eidas-high"
    
    public static let KEY_USAGE = "key-usage" // "authn" or "signing"
    public static let KEY_NAME = "key-name"
    public static let KEY_ALGORITHM = "key-algorithm"
    public static let KEY_LENGTH = "key-length"
    public static let KEY_PREGEN = "key-pregenerated"
    
    public static let RSA_EXPONENT = "rsa-public-exponent"
    public static let ECC_CURVE = "ecc-curve"
    public static let CREATED_DATE = "created-date"
    
    
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
        if key.getKeyAlias()    != nil { keyUriMap[KeyURI.KEY_NAME]      = key.getKeyAlias() }
        
        if let keyAlgorithm = key.getAlgorithm() {
            keyUriMap[KeyURI.KEY_ALGORITHM] = (keyAlgorithm.isEc() ? "EC" : "RSA")
            keyUriMap[KeyURI.KEY_LENGTH]    = String(keyAlgorithm.bits)
            
            if keyAlgorithm.isEc() {
                keyUriMap[KeyURI.ECC_CURVE] = keyAlgorithm.curve
            } else {
                //TODO: RSA Exponent
            }
        }
        
        if let createdDate = key.getCreatedDate() {
            keyUriMap[KeyURI.CREATED_DATE] = ISO8601DateFormatter().string(from: createdDate)
        }
        
        if let keyUsage = key.getKeyUsages() {
            keyUriMap[KeyURI.KEY_USAGE] = keyUsage.joined(separator: ",")
        }
        
        if let loa = key.getLoa() {
            let loaStringArray = loa.map { $0.toString() }
            let loaString = loaStringArray.joined(separator: ",")
            keyUriMap[KeyURI.LOA] = loaString
        }
        
        if let msisdn = key.getAttributeValue(attrName: KeyURI.MSISDN) {
            keyUriMap[KeyURI.MSISDN] = msisdn
        }
        
        if let serial = key.getAttributeValue(attrName: KeyURI.SERIAL) {
            keyUriMap[KeyURI.SERIAL] = serial
        }
        
        if let sscdInfo = key.getSscdInfo() {
            keyUriMap[KeyURI.SSCD] = sscdInfo.getSscdName()
            keyUriMap[KeyURI.COUNTRY] = sscdInfo.getCountry()
            keyUriMap[KeyURI.PROVIDER] = sscdInfo.getProvider()
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
