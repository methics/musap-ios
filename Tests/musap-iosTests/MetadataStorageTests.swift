import XCTest
import musap_ios
@testable import musap_ios

class MetadataStorageTests: XCTestCase {

    var metadataStorage: MetadataStorage!
    let testKeyAlias = "testKeyAlias"
    let testKeyId = "12345"
    let testSSCDId = "testSSCDId"
    let testSscdType = "SE"
    let key = "ABCSFV".data(using: .utf8)!
    let testKeyURI = KeyURI(keyUri: "keyuri:key?name=testKeyAlias&sscd=SE&loa=TestLOA")
    let testSscd = SecureEnclaveSscd()


    override func setUpWithError() throws {
        super.setUp()
        metadataStorage = MetadataStorage()
        
        // Remove any existing data to ensure a clean state for tests
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: testKeyAlias)
        userDefaults.removeObject(forKey: testKeyAlias)
        userDefaults.removeObject(forKey: testSSCDId)
        userDefaults.synchronize()
    }

    override func tearDownWithError() throws {
        metadataStorage = nil
        UserDefaults.standard.synchronize()
        super.tearDown()
    }

    
    func testStoreAndListKeys() throws {
        let testKey = MusapKey(keyAlias: self.testKeyAlias, keyId: self.testKeyId, sscdType: self.testSscdType, publicKey: PublicKey(publicKey: self.key), keyUri: self.testKeyURI )
        let testSSCD = MusapSscd(impl: self.testSscd)

        try metadataStorage.addKey(key: testKey, sscd: testSSCD.getSscdInfo()!)

        let keys = metadataStorage.listKeys()
        XCTAssertEqual(keys.count, 1)
        
        for key in keys {
            XCTAssertEqual(key.getKeyId(), testKey.getKeyId())
        }
    }
     

    func testStoreAndListSSCDs() {
        guard let amountBefore = MusapClient.listEnabledSscds() else {
            XCTFail()
            return
        }

        let seSscd = SecureEnclaveSscd()
        MusapClient.enableSscd(sscd: seSscd, sscdId: self.testSSCDId)
        let testSSCD = MusapSscd(impl: seSscd)
        let testInfo = testSSCD.getSscdInfo()

        
        metadataStorage.addSscd(sscd: testInfo!)
        guard let sscds = MusapClient.listEnabledSscds() else {
            XCTFail()
            return
        }
        print("amountBefore: \(amountBefore.count)")
        print("sscds amount: \(sscds.count)")

        XCTAssertNotEqual(amountBefore.count, sscds.count)
    }
    
    func testRemoveKey() {
        let key = "ABCSFV".data(using: .utf8)!
        let testKey = MusapKey(keyAlias: "removeKeyAlias", keyId: "removeKeyId1234", sscdType: "testSSCD", publicKey: PublicKey(publicKey: key), keyUri: KeyURI(keyUri: "keyuri:key?name=testKeyAlias&sscd=TestSSCD&loa=TestLOA"))
        let storage = MetadataStorage()

        let sscd = SecureEnclaveSscd()
        
        let before = metadataStorage.listKeys().count
        
        try? storage.addKey(key: testKey, sscd: sscd.getSscdInfo())
        var keys = metadataStorage.listKeys()
        
        XCTAssertNotEqual(before, keys.count)

        let result = metadataStorage.removeKey(key: testKey)
        XCTAssertTrue(result)
        
        let afterRemove = metadataStorage.listKeys()

        XCTAssertNotEqual(keys.count, afterRemove.count)
    }

    
    func testUpdateKeyMetaData() {
        let key = "ABCSFV".data(using: .utf8)!
        let seSscd = SecureEnclaveSscd()

        MusapClient.enableSscd(sscd: seSscd, sscdId: self.testKeyId)
        let testSSCD = MusapSscd(impl: seSscd)
        let testInfo = testSSCD.getSscdInfo()
        
        let originalKey = MusapKey(keyAlias: self.testKeyAlias,  keyId: "12345", sscdType: seSscd.getSscdInfo().getSscdType(), publicKey: PublicKey(publicKey: key), keyUri: KeyURI(keyUri: "keyuri:key?name=TestName&sscd=TestSSCD&loa=TestLOA"))
                
        do {
            try metadataStorage.addKey(key: originalKey, sscd: testInfo!)
        } catch {
            print("Could not add key")
        }
        let updateRequest = UpdateKeyReq(key: originalKey, keyAlias: "ChangedAlias", did: nil, attributes: [], role: "personal", state: "default")

        let result = metadataStorage.updateKeyMetaData(req: updateRequest)

        XCTAssertTrue(result)
        let keys = metadataStorage.listKeys()
        XCTAssertEqual(keys.count, 1)
        
        for key in keys {
            if let keyAlias = key.getKeyAlias() {
                XCTAssertEqual(keyAlias, "ChangedAlias")
            }
        }

    }
    
    func testRemoveSscd() {
        
    }
    
    func testAddImportData() {
        
    }
    
    func testGetImportData() {
        
    }
    

}
