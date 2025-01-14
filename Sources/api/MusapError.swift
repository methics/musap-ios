//
//  MusapError.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public enum MusapError: Error {
    case wrongParam
    case missingParam
    case invalidAlgorithm
    case unknownKey
    case unsupportedData
    case keygenUnsupported
    case bindUnsupported
    case timedOut
    case userCancel
    case keyBlocked
    case sscdBlocked
    case internalError
    case illegalArgument
    case keyAlreadyExists
    case sscdAlreadyExists
    
    public var errorCode: Int {
        switch self {
        case .wrongParam:         return 101
        case .missingParam:       return 102
        case .invalidAlgorithm:   return 103
        case .unknownKey:         return 105
        case .keyAlreadyExists:   return 106
        case .unsupportedData:    return 107
        case .keygenUnsupported:  return 108
        case .bindUnsupported:    return 109
        case .timedOut:           return 208
        case .userCancel:         return 401
        case .keyBlocked:         return 402
        case .sscdBlocked:        return 403
        case .sscdAlreadyExists:  return 404
        case .internalError:      return 900
        case .illegalArgument:    return 900
        }
    }
    
}

public class MusapException: Error {
    public let error: MusapError
    public let errorName: String
    
    public init(_ error: MusapError, _ msg: String = "") {
        self.error = error
        self.errorName = MusapException.getErrorName(error)
        print("MusapException: \(errorName) - \(msg)")
    }
    
    private static func getErrorName(_ error: MusapError) -> String {
        switch error {
        case .wrongParam:         return "wrong_param"
        case .missingParam:       return "missing_param"
        case .invalidAlgorithm:   return "invalid_algorithm"
        case .unknownKey:         return "unknown_key"
        case .keyAlreadyExists:   return "key_already_exists"
        case .unsupportedData:    return "unsupported_data"
        case .keygenUnsupported:  return "keygen_unsupported"
        case .bindUnsupported:    return "bind_unsupported"
        case .timedOut:           return "timed_out"
        case .userCancel:         return "user_cancel"
        case .keyBlocked:         return "key_blocked"
        case .sscdBlocked:        return "sscd_blocked"
        case .sscdAlreadyExists:  return "sscd_already_exists"
        case .internalError:      return "internal_error"
        case .illegalArgument:    return "illegal_argument"
        }
    }
}
