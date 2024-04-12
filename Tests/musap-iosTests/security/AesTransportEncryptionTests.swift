import XCTest
import CryptoKit
@testable import musap_ios
import CommonCrypto
import Foundation
import Security

final class AesTransportEncryptionTests: XCTestCase {
    
    let message = "teststring"
    let expectedEncryptedBase64 = "WS1XGISmwEXYo60botyTPA=="
    let iv = "MTIzNDU2Nzg5ODc2NTQzMg=="
    let secret = "1234123456789878"

    override func setUpWithError() throws {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEncrypt() throws {
        let storage = MockKeyStorage()
        let encryption = AesTransportEncryption(keyStorage: storage)
        
        guard let encodedKey = secret.data(using: .utf8)
        else {
            XCTFail("Failed to encode key or IV")
            return
        }

        let secretKey = SymmetricKey(data: encodedKey)
        try storage.storeKey(keyName: MusapKeyGenerator.TRANSPORT_KEY_ALIAS, keyData: encodedKey)

        let encryptedPayload = encryption.encrypt(message: message, iv: self.iv)

        // Convert the encrypted payload to Base64 to match with the expected encrypted string.
        let encryptedPayloadBase64 = encryptedPayload?.payload
        
        XCTAssertEqual(encryptedPayloadBase64, expectedEncryptedBase64, "Output is AES encrypted")
        XCTAssertEqual(encryptedPayload?.iv, iv, "Payload contains IV")
    }
    
    func testDecrypt() throws {
        let storage = MockKeyStorage()
        let encryption = AesTransportEncryption(keyStorage: storage)

        guard let encodedKey = secret.data(using: .utf8),
              let encryptedData = Data(base64Encoded: expectedEncryptedBase64) else {
            XCTFail("Failed to encode data")
            return
        }

        let key = SymmetricKey(data: encodedKey)
        try storage.storeKey(keyName: MusapKeyGenerator.TRANSPORT_KEY_ALIAS, keyData: encodedKey)

        let decrypted = encryption.decrypt(message: encryptedData, iv: iv)

        XCTAssertEqual(decrypted, self.message, "Output is decrypted")
    }
}
