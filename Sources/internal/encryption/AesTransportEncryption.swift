//
//  File.swift
//  
//
//  Created by Teemu Mänttäri on 2.4.2024.
//

import Foundation
import CommonCrypto

public class AesTransportEncryption: TransportEncryption {
    
    private let keyStorage: KeyStorage
    private let cipher: String
    

    public init(keyStorage: KeyStorage) {
        self.keyStorage = keyStorage
        self.cipher = "" //TODO
    }
    
    public init(keyStorage: KeyStorage, cipher: String) {
        self.keyStorage = keyStorage
        self.cipher = cipher
    }
        
    public func encrypt(message: String) -> PayloadHolder? {
        return self.encrypt(message: message, iv: nil)
    }
    
    public func encrypt(message: String, iv: String?) -> PayloadHolder? {
        AppLogger.shared.log("Starting to encrypt a message...")
        
        guard let keyData = self.keyStorage.loadKey(keyName: MusapKeyGenerator.TRANSPORT_KEY_ALIAS),
              [16, 32].contains(keyData.count) // 16 bytes AES-128, 32 bytes AES-256
        else {
            AppLogger.shared.log("Invalid key or key length", .error)
            return nil
        }
        
        guard let messageData = message.data(using: .utf8) else {
            AppLogger.shared.log("Unable to message into Data()")
            return nil
        }
        
        if let iv = iv {
            AppLogger.shared.log("IV: \(iv)")
        } else {
            AppLogger.shared.log("No IV provided")
        }
        
        let iv = iv != nil ? Data(base64Encoded: iv!)! : randomIV()
        var numBytesEncrypted = 0
        let bufferSize = messageData.count + kCCBlockSizeAES128
        var encryptedData = Data(count: messageData.count + kCCBlockSizeAES128)
        
        
        let status: CCCryptorStatus = encryptedData.withUnsafeMutableBytes { encryptedBytes in
            messageData.withUnsafeBytes { messageBytes in
                iv.withUnsafeBytes { ivBytes in
                    keyData.withUnsafeBytes { keyBytes in
                        return CCCrypt(CCOperation(kCCEncrypt),
                                       CCAlgorithm(kCCAlgorithmAES128),
                                       CCOptions(kCCOptionPKCS7Padding),
                                       keyBytes.baseAddress!,
                                       keyData.count,
                                       ivBytes.baseAddress!,
                                       messageBytes.baseAddress!,
                                       messageData.count,
                                       encryptedBytes.baseAddress!,
                                       bufferSize,
                                       &numBytesEncrypted)
                    }
                }
            }
        }

        guard status == kCCSuccess else {
            AppLogger.shared.log("Failed to encrypt: \(status)", .error)
            return nil
        }

        let finalEncryptedData = encryptedData.prefix(numBytesEncrypted)

        return PayloadHolder(payload: finalEncryptedData.base64EncodedString(), iv: iv.base64EncodedString())
    }
    
    public func decrypt(message: Data, iv: String) -> String? {
        AppLogger.shared.log("Trying to decrypt a message...")
        
        guard let keyData = self.keyStorage.loadKey(keyName: MusapKeyGenerator.TRANSPORT_KEY_ALIAS), [16, 32].contains(keyData.count) else {
            AppLogger.shared.log("Invalid key or key length", .error)
            return nil
        }

        let iv = Data(base64Encoded: iv)!
        let bufferSize = message.count
        var decryptedData = Data(count: message.count)
        var numBytesDecrypted = 0

        let status: CCCryptorStatus = decryptedData.withUnsafeMutableBytes { decryptedBytes in
            message.withUnsafeBytes { encryptedBytes in
                iv.withUnsafeBytes { ivBytes in
                    keyData.withUnsafeBytes { keyBytes in
                        return CCCrypt(CCOperation(kCCDecrypt),
                                       CCAlgorithm(kCCAlgorithmAES),
                                       CCOptions(kCCOptionPKCS7Padding),
                                       keyBytes.baseAddress!,
                                       keyData.count,
                                       ivBytes.baseAddress!,
                                       encryptedBytes.baseAddress!,
                                       message.count,
                                       decryptedBytes.baseAddress!,
                                       bufferSize,
                                       &numBytesDecrypted)
                    }
                }
            }
        }

        guard status == kCCSuccess else {
            AppLogger.shared.log("Error in decryption: \(status)")
            return nil
        }

        let finalDecryptedData = decryptedData.prefix(numBytesDecrypted)
        return String(data: finalDecryptedData, encoding: .utf8)
    }
    
    
    
    private func randomIV() -> Data {
        var iv = Data(count: 16)
        _ = iv.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!)
        }
        return iv
    }
    
    
}
