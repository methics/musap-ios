//
//  HmacGenerator.swift
//
//
//  Created by Teemu Mänttäri on 3.4.2024.
//

import Foundation
import CommonCrypto


public class HmacGenerator: MacGenerator {
    
    private let keyStorage: KeyStorage
    private static let HASH_ALGORITHM = kCCHmacAlgSHA256
    
    public init(keyStorage: KeyStorage) {
        self.keyStorage = keyStorage
    }
    
    public func generate(message: String, iv: String, transId: String?, type: String) throws -> String {
        let hmacBytes = try self.generateHmacBytes(message: message, iv: iv, transId: transId, type: type)
        
        return self.toHexString(data: hmacBytes)
    }
    
    public func validate(message: String, iv: String, transId: String?, type: String, mac: String) throws -> Bool {
        
        
        let calculatedHmac = try self.generateHmacBytes(message: message, iv: iv, transId: transId, type: mac)
        guard let receivedHmac = self.parseHex(mac) else {
            print("Could not parseHex(mac)")
            throw MusapError.internalError
        }
        
        print("calculated Hmac: \(self.toHexString(data: calculatedHmac))")
        print("Received Hmac: \(self.toHexString(data: receivedHmac))")
        
        return calculatedHmac == receivedHmac
    }
    
    func hmac(key: Data, message: Data) -> Data? {
        var result = Data(count: Int(CC_SHA256_DIGEST_LENGTH)) // Determine length somehow
        
        result.withUnsafeMutableBytes { resultBytes in
            message.withUnsafeBytes { messageBytes in
                key.withUnsafeBytes { keyBytes in
                    CCHmac(CCHmacAlgorithm(HmacGenerator.HASH_ALGORITHM),
                           keyBytes.baseAddress,
                           key.count,
                           messageBytes.baseAddress,
                           message.count,
                           resultBytes.baseAddress)
                }
            }
        }
        return result
    }
    
    private func generateHmacBytes(message: String, iv: String, transId: String?, type: String) throws -> Data {

        print("Message= \(message) iv= \(iv) transId= \(transId ?? "") type=\(type)")
        
        let input = transId ?? "" + type + iv + message
        guard let macKey = self.keyStorage.loadKey(keyName: MusapKeyGenerator.MAC_KEY_ALIAS) else {
            throw MusapError.unknownKey
        }
        
        guard let inputData = input.data(using: .utf8) else {
            throw MusapError.internalError
        }
    
        guard let hmacData = self.hmac(key: macKey, message: inputData) else {
            throw MusapError.internalError
        }
        
        return hmacData
    }
    
    func toHexString(data: Data) -> String {
        return data.map { String(format: "%02hhx", $0) }.joined()
    }
    
    func parseHex(_ hexString: String) -> Data? {
        var data = Data(capacity: hexString.count / 2)
        
        var index = hexString.startIndex
        while index < hexString.endIndex {
            let nextIndex = hexString.index(index, offsetBy: 2)
            if nextIndex <= hexString.endIndex {
                let hexPair = hexString[index..<nextIndex]
                if let byte = UInt8(hexPair, radix: 16) {
                    data.append(byte)
                } else {
                    return nil  // Invalid hex string
                }
                index = nextIndex
            } else {
                // Hex string has an odd number of digits or is malformed
                return nil
            }
        }
        
        return data
    }

    
}
