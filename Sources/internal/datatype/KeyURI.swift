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
    
    public init(params: [String: String]) {
        self.keyUriMap = params
    }
    
    private func parseUri(_ keyUri: String) -> [String: String] {
        AppLogger.shared.log("Trying to parse key URI: \(keyUri)")
        
        var keyUriMap = [String: String]()

        if keyUri.hasPrefix("keyuri:key") {
            // Handle keyuri:key case
            let cleanedUri = keyUri.replacingOccurrences(of: "keyuri:key?", with: "")
            let pairs = cleanedUri.components(separatedBy: "&")

            for pair in pairs {
                let components = pair.components(separatedBy: "=")
                if components.count == 2 {
                    let key = components[0]
                    let value = components[1]
                    keyUriMap[key] = value
                    AppLogger.shared.log("Parsed: \(key)=\(value)")
                } else {
                    AppLogger.shared.log("Ignoring invalid pair \(pair)")
                }
            }
        } else if keyUri.hasPrefix("mss:") {
            // Handle mss: case
            guard keyUri.firstIndex(of: ",") != nil else {
                return keyUriMap
            }

            let parts = keyUri.replacingOccurrences(of: "mss:", with: "").components(separatedBy: ",")

            for attribute in parts {
                if attribute.contains("=") {
                    let split = attribute.components(separatedBy: "=")
                    guard split.count >= 2 else { continue }

                    let key = split[0]
                    let value = split[1]
                    AppLogger.shared.log("Parsed: \(key)=\(value)")
                    keyUriMap[key] = value
                } else {
                    AppLogger.shared.log("Ignoring invalid attribute: \(attribute)")
                }
            }
        } else {
            AppLogger.shared.log("Unable to parse URI - unsupported format")
        }

        AppLogger.shared.log("Parsed KeyURI to: \(keyUriMap)")
        return keyUriMap
    }

    // The query parameters of keyUri in the MetadataStorage are in random order, so we compare each param separately
    public func matches(keyUri: KeyURI) -> Bool {
        if self == keyUri {
            return true
        }

        let selfKeys = Set(self.keyUriMap.keys)
        let otherKeys = Set(keyUri.keyUriMap.keys)

        guard selfKeys == otherKeys else {
            return false
        }

        for key in selfKeys {
            guard let selfValue = self.keyUriMap[key],
                  let otherValue = keyUri.keyUriMap[key] else {
                return false
            }

            // Directly compare the values
            if selfValue != otherValue {
                return false
            }
        }

        return true
   }

    public func getDisplayString(_ params: String...) -> String {
        if params.isEmpty {
            return self.getUri()
        }
        
        var subParams: [String: String] = [:]

        for param in params {
            guard let value = keyUriMap[param] else {
                continue
            }
            subParams[param] = value
        }

        return KeyURI(params: subParams).getUri()
    }
    
    /**
     Get a String representation of this KeyURI
     - returns: KeyURI as String
     */
    public func getUri() -> String {
        var components = [String]()
        var isFirst = true

        for (key, value) in self.keyUriMap {
            let prefix = isFirst ? "?" : "&"
            components.append("\(prefix)\(key)=\(value)")
            isFirst = false
        }

        return "keyuri:key" + components.joined()
    }

    
    /**
     Check if this KeyURI is a partial match of another KeyURI.
     Partial match is defined as:
     1. This KeyURI has all parameters of the given KeyURI.
     2. For matching parameters, the parameter value of this KeyURI contains
        all comma-separated values of the given KeyURI.
     - Parameter keyURI: The KeyURI to compare against.
     - Returns: `true` if it is a partial match, `false` otherwise.
     */
    public func isPartialMatch(keyURI: KeyURI) -> Bool {
        for (key, givenValue) in keyURI.keyUriMap {
            guard let thisValue = self.keyUriMap[key]?.lowercased() else {
                AppLogger.shared.log("This key uri does not have param \(key) - not a match")
                return false
            }

            let givenValueLowercased = givenValue.lowercased()
            if !areParamsPartialMatch(thisParams: thisValue, searchParam: givenValueLowercased) {
                AppLogger.shared.log("Param \(thisValue) is not a partial match with \(givenValue)")
                return false
            }
        }
        return true
    }
    
    //TODO: Confirm is this what we are trying to do?
    public func areParamsPartialMatch(thisParams: String, searchParam: String) -> Bool {
        let thisArr   = thisParams.split(separator: ",")
        let searchArr = searchParam.split(separator: ",")
        
        let thisSet   = Set(thisArr)
        let searchSet = Set(searchArr)
        
        return searchSet.isSubset(of: thisSet)
    }
    
    public func areParamsExactMatch(thisArr: [String], searchArr: [String]) -> Bool {
        let set1 = Set(thisArr)
        let set2 = Set(searchArr)
        return set1 == set2
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
    
    public func getName() -> String? {
        return self.keyUriMap[KeyURI.KEY_NAME]
    }
    
    public func getCountry() -> String? {
        return self.keyUriMap[KeyURI.COUNTRY]
    }
    
}
