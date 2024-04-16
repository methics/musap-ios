//
//  MusapLoa.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 7.11.2023.
//

import Foundation

public class MusapLoa: Codable, Comparable {
    
    public static let LOA_SCHEME_EIDAS   = "EIDAS-2014"
    public static let LOA_SCHEME_ISO     = "ISO-29115"
    public static let LOA_SCHEME_NIST    = "NIST-SP-800"
    public static let LOA_SCHEME_UNKNOWN = "UNKNOWN"
    
    public static let EIDAS_LOW         = MusapLoa(loa: "low",         number: 1, scheme: LOA_SCHEME_EIDAS)
    public static let EIDAS_SUBSTANTIAL = MusapLoa(loa: "substantial", number: 3, scheme: LOA_SCHEME_EIDAS)
    public static let EIDAS_HIGH        = MusapLoa(loa: "high",        number: 4, scheme: LOA_SCHEME_EIDAS)
    
    public static let ISO_LOA1          = MusapLoa(loa: "loa1",        number: 1, scheme: LOA_SCHEME_ISO)
    public static let ISO_LOA2          = MusapLoa(loa: "loa2",        number: 2, scheme: LOA_SCHEME_ISO)
    public static let ISO_LOA3          = MusapLoa(loa: "loa3",        number: 3, scheme: LOA_SCHEME_ISO)
    public static let ISO_LOA4          = MusapLoa(loa: "loa4",        number: 4, scheme: LOA_SCHEME_ISO)
    
    public static let NIST_IAL1         = MusapLoa(loa: "ial1",        number: 1, scheme: LOA_SCHEME_NIST)
    public static let NIST_IAL2         = MusapLoa(loa: "ial2",        number: 2, scheme: LOA_SCHEME_NIST)
    public static let NIST_IAL3         = MusapLoa(loa: "ial3",        number: 3, scheme: LOA_SCHEME_NIST)
    
    public static let NIST_AAL1         = MusapLoa(loa: "aal1",        number: 1, scheme: LOA_SCHEME_NIST)
    public static let NIST_AAL2         = MusapLoa(loa: "aal2",        number: 2, scheme: LOA_SCHEME_NIST)
    public static let NIST_AAL3         = MusapLoa(loa: "aal3",        number: 3, scheme: LOA_SCHEME_NIST)

    private var loa:    String
    private var scheme: String
    private var number: Int
    
        
    public init(loa: String, number: Int, scheme: String) {
        self.loa    = loa
        self.number = number
        self.scheme = scheme
    }
    
    public func getLoa() -> String {
        return self.loa
    }
    
    public func getScheme() -> String {
        return self.scheme
    }
    
    public func compareLoA(other: MusapLoa) -> Bool {
        return self.number >= other.number
    }
    
    public func toString() -> String {
        var loaString = ""
        if self.scheme == MusapLoa.LOA_SCHEME_EIDAS {
            switch self.scheme {
            case MusapLoa.LOA_SCHEME_EIDAS:
                loaString.append("eidas-")
            case MusapLoa.LOA_SCHEME_ISO:
                loaString.append("iso-")
            case MusapLoa.LOA_SCHEME_NIST:
                loaString.append("nist-")
            default:
                break
            }
        }
        loaString.append(self.loa)
        return loaString
    }

    public static func compareLoA(first: MusapLoa?, second: MusapLoa?) -> Bool {
        guard let first = first else {
            return false
        }
        guard second != nil else {
            return false
        }
        
        if let secondLoa = second {
            return first.compareLoA(other: secondLoa)
        }
        return false
        
    }

    public static func < (lhs: MusapLoa, rhs: MusapLoa) -> Bool {
        return lhs.number < rhs.number
    }

    public static func == (lhs: MusapLoa, rhs: MusapLoa) -> Bool {
        return lhs.number == rhs.number
    }

}
