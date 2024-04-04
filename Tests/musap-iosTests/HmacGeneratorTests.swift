import XCTest
@testable import musap_ios

class HmacGeneratorTests: XCTestCase {

    var hmacGenerator: HmacGenerator!
    var keyStorage: KeyStorage!

    override func setUpWithError() throws {
        keyStorage = KeychainKeystorage() // This would use the real Keychain
        hmacGenerator = HmacGenerator(keyStorage: keyStorage)
        
        // Store a test key in the keychain for testing
        let testKeyData = "testKey".data(using: .utf8)!
        try keyStorage.storeKey(keyName: MusapKeyGenerator.MAC_KEY_ALIAS, keyData: testKeyData)
    }

    override func tearDownWithError() throws {
        // Clean up keychain items
        // ... Code to delete the test key from the keychain ...
    }

    func testGenerateHmac_Success() throws {
        let message = "testMessage"
        let iv = "testIV"
        let transId = "testTransId"
        let type = "testType"
        
        let hmacString = try hmacGenerator.generate(message: message, iv: iv, transId: transId, type: type)
        
        XCTAssertNotNil(hmacString, "Generated HMAC should not be nil")
        // You may also want to check the length of the HMAC string based on the expected length
    }

    func testValidateHmac_Success() throws {
        let message = "testMessage"
        let iv = "testIV"
        let transId = "testTransId"
        let type = "testType"
        
        // First generate an HMAC to test against
        let hmacString = try hmacGenerator.generate(message: message, iv: iv, transId: transId, type: type)
        
        // Now validate the HMAC with the same parameters
        let isValid = try hmacGenerator.validate(message: message, iv: iv, transId: transId, type: type, mac: hmacString)
        
        XCTAssertTrue(isValid, "The HMAC validation should be true for a correct HMAC")
    }
    
    
    // TODO: Additional tests can be written to check for failures by providing incorrect MAC strings, or by altering message, iv, transId, type
    
}
