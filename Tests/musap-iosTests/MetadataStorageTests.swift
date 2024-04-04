import XCTest
import musap_ios
@testable import musap_ios

class MetadataStorageTests: XCTestCase {

    var metadataStorage: MetadataStorage!
    let testKeyAlias = "testKeyAlias"
    let testKeyName = "testKeyName"
    let testSSCDId = "testSSCDId"

    override func setUpWithError() throws {
        super.setUp()
        metadataStorage = MetadataStorage()
        
        // Remove any existing data to ensure a clean state for tests
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: testKeyAlias)
        userDefaults.removeObject(forKey: testKeyName)
        userDefaults.removeObject(forKey: testSSCDId)
        //userDefaults.removeObject(forKey: MetadataStorage.KEY_NAME_SET)
        //userDefaults.removeObject(forKey: MetadataStorage.SSCD_ID_SET)
        userDefaults.synchronize()
    }

    override func tearDownWithError() throws {
        metadataStorage = nil
        UserDefaults.standard.synchronize()
        super.tearDown()
    }

    /*
    func testStoreAndListKeys() throws {
        let publickeyData = ""
        let testKey = MusapKey(keyAlias: "MyKey", sscdType: "TestSscd", publicKey: PublicKey, keyUri: <#T##KeyURI?#>)
        let testSSCD = MusapSscd(/* initializer parameters */)

        try metadataStorage.storeKey(key: testKey, sscd: testSSCD)

        let keys = metadataStorage.listKeys()
        XCTAssertEqual(keys.count, 1)
        XCTAssertEqual(keys.first, testKey)
    }
     */

    func testStoreAndListSSCDs() {
        let testSSCD = MusapSscd(impl: SecureEnclaveSscd())
        let testInfo = testSSCD.getSscdInfo()

        metadataStorage.addSscd(sscd: testInfo!)
        let sscds = metadataStorage.listActiveSscds()

        XCTAssertEqual(sscds.count, 1)
    }
    
    func testRemoveKey() {
        let key = "ABCSFV".data(using: .utf8)!
        let testKey = MusapKey(keyAlias: "TestKey", sscdType: "TestSscd", publicKey: PublicKey(publicKey: key), keyUri: KeyURI(keyUri: "keyuri:key?name=TestName&sscd=TestSSCD&loa=TestLOA"))
        let storage = MetadataStorage()

        let sscd = SecureEnclaveSscd()
        
        try? storage.addKey(key: testKey, sscd: sscd.getSscdInfo())
        var keys = metadataStorage.listKeys()
        XCTAssertEqual(keys.count, 1)

        let result = metadataStorage.removeKey(key: testKey)
        XCTAssertTrue(result)

        keys = metadataStorage.listKeys()
        XCTAssertTrue(keys.isEmpty)
    }

    /*
    func testUpdateKeyMetaData() {
        let originalKey = MusapKey(/* initializer parameters */)
        let updateRequest = UpdateKeyReq(/* initializer parameters */)

        try? metadataStorage.storeKey(key: originalKey)
        let result = metadataStorage.updateKeyMetaData(req: updateRequest)

        XCTAssertTrue(result)
        let keys = metadataStorage.listKeys()
        XCTAssertEqual(keys.count, 1)

        // Test the updated properties here
    }
     */

    // ... More tests for different scenarios ...
    
}
