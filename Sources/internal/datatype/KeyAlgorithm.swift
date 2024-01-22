//
//  KeyAlgorithm.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.11.2023.
//


import Foundation
import Security

public struct KeyAlgorithm: Codable, Equatable {
    
    static let PRIMITIVE_RSA = kSecAttrKeyTypeRSA as String
    static let PRIMITIVE_EC = kSecAttrKeyTypeECSECPrimeRandom as String

    static let CURVE_SECP256K1 = "secp256k1"
    static let CURVE_SECP384K1 = "secp384k1"
    static let CURVE_SECP256R1 = "secp256r1"
    static let CURVE_SECP384R1 = "secp384r1"
    
    static let RSA_1K = KeyAlgorithm(primitive: PRIMITIVE_RSA, bits: 1024) // YubiKey supports 1024 and 2048 only
    static let RSA_2K = KeyAlgorithm(primitive: PRIMITIVE_RSA, bits: 2048)
    static let RSA_4K = KeyAlgorithm(primitive: PRIMITIVE_RSA, bits: 4096)
    static let ECC_P256_K1 = KeyAlgorithm(primitive: PRIMITIVE_EC, curve: CURVE_SECP256K1, bits: 256)
    static let ECC_P384_K1 = KeyAlgorithm(primitive: PRIMITIVE_EC, curve: CURVE_SECP384K1, bits: 384)
    static let ECC_P256_R1 = KeyAlgorithm(primitive: PRIMITIVE_EC, curve: CURVE_SECP256R1, bits: 256)
    static let ECC_P384_R1 = KeyAlgorithm(primitive: PRIMITIVE_EC, curve: CURVE_SECP384R1, bits: 384)

    let primitive: String
    let curve: String?
    let bits: Int

    /// Initialize for RSA with bit size
    init(primitive: String, bits: Int) {
        self.primitive = primitive
        self.bits = bits
        self.curve = nil
    }

    /// Initialize for EC with a curve and bit size
    init(primitive: String, curve: String, bits: Int) {
        self.primitive = primitive
        self.curve = curve
        self.bits = bits
    }

    /// Check if it is RSA key
    func isRsa() -> Bool {
        return primitive == KeyAlgorithm.PRIMITIVE_RSA
    }

    /// Check if it is EC key
    func isEc() -> Bool {
        return primitive == KeyAlgorithm.PRIMITIVE_EC
    }

    /// Description of key algorithm
    func description() -> String {
        if let curve = curve {
            return "[\(primitive)/\(curve)/\(bits)]"
        } else {
            return "[\(primitive)/\(bits)]"
        }
    }
    
    func toSignatureAlgorithm() -> SignatureAlgorithm {
        if isRsa() {
            switch bits {
            case 1024, 2048:
                return SignatureAlgorithm(algorithm: SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256)
            case 4096:
                return SignatureAlgorithm(algorithm: SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256)
            default:
                return SignatureAlgorithm(algorithm: SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256)
            }
        }
        
        if isEc() {
            switch bits {
            case 256:
                return SignatureAlgorithm(algorithm: SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256)
            case 384:
                return SignatureAlgorithm(algorithm: SecKeyAlgorithm.ecdsaSignatureMessageX962SHA384)
            case 512:
                return SignatureAlgorithm(algorithm: SecKeyAlgorithm.ecdsaSignatureMessageX962SHA512)
            default:
                return SignatureAlgorithm(algorithm: SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256)
            }
        }
        
        return SignatureAlgorithm(algorithm: SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256)
        
    }
}

enum KeyAlgorithmEnum {
    case rsa(Int)   // Bits
    case ec(ECType) // EC Curve Type

    enum ECType {
        case secp256k1
        case secp384k1
        case secp256r1 // This is Secure enclave supported
        case secp384r1
        case ed25519

        var bits: Int {
            switch self {
            case .secp256k1, .secp256r1, .ed25519:
                return 256
            case .secp384k1, .secp384r1:
                return 384
            }
        }

        var curveName: String {
            switch self {
            case .secp256k1: return "secp256k1"
            case .secp384k1: return "secp384k1"
            case .secp256r1: return "secp256r1"
            case .secp384r1: return "secp384r1"
            case .ed25519:   return "Ed25519"
            }
        }
    }

    var description: String {
        switch self {
        case .rsa(let bits):
            return "[RSA/\(bits)]"
        case .ec(let type):
            return "[EC/\(type.curveName)/\(type.bits)]"
        }
    }
}
