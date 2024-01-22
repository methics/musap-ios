//
//  MusapLoa.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 7.11.2023.
//

import Foundation

public class MusapLoa: Codable, Comparable {
    
    public static let LOA_SCHEME_EIDAS = "EIDAS-2014"
    public static let LOA_SCHEME_ISO   = "ISO-29115"
    
    public static let EIDAS_LOW         = MusapLoa(loa: "low",         number: 1, scheme: LOA_SCHEME_EIDAS)
    public static let EIDAS_SUBSTANTIAL = MusapLoa(loa: "substantial", number: 3, scheme: LOA_SCHEME_EIDAS)
    public static let EIDAS_HIGH        = MusapLoa(loa: "high",        number: 4, scheme: LOA_SCHEME_EIDAS)
    public static let ISO_LOA1          = MusapLoa(loa: "loa1",        number: 1, scheme: LOA_SCHEME_ISO)
    public static let ISO_LOA2          = MusapLoa(loa: "loa2",        number: 2, scheme: LOA_SCHEME_ISO)
    public static let ISO_LOA3          = MusapLoa(loa: "loa3",        number: 3, scheme: LOA_SCHEME_ISO)
    public static let ISO_LOA4          = MusapLoa(loa: "loa4",        number: 4, scheme: LOA_SCHEME_ISO)
    
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

    //TODO: Go through these compares
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
