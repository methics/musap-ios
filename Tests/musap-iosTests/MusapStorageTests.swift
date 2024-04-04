import XCTest
@testable import musap_ios

class MusapStorageTests: XCTestCase {

    var musapStorage: MusapStorage!
    var relyingParty = RelyingParty(name: "TestRP", linkId: "123-abc")
    var musapLink = MusapLink(url: "http://some.url", musapId: "123-abc")
    
    override func setUpWithError() throws {
        super.setUp()
        musapStorage = MusapStorage()
        clearUserDefaults()
    }

    override func tearDownWithError() throws {
        clearUserDefaults()
        musapStorage = nil
        super.tearDown()
    }
    
    private func clearUserDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }

    func testStoreAndRetrieveRelyingParties() {
        let rp = self.relyingParty
        musapStorage.storeRelyingParty(rp: rp)
        
        let retrievedRPs = musapStorage.listRelyingParties()
        
        XCTAssertNotNil(retrievedRPs)
        XCTAssertEqual(retrievedRPs?.count, 1)
    }
    
    func testRemoveRelyingParty() {
        let rp = self.relyingParty
        musapStorage.storeRelyingParty(rp: rp)
        
        var retrievedRPs = musapStorage.listRelyingParties()
        XCTAssertEqual(retrievedRPs?.count, 1)

        let removed = musapStorage.removeRelyingParty(rp: rp)
        XCTAssertTrue(removed)
        
        retrievedRPs = musapStorage.listRelyingParties()
        XCTAssertTrue(retrievedRPs?.isEmpty ?? false)
    }
    
    func testStoreAndRetrieveMusapLink() {
        let musapLink = self.musapLink
        musapStorage.storeLink(link: musapLink)
        
        let retrievedLink = musapStorage.getMusaplink()
        
        XCTAssertNotNil(retrievedLink)
        //XCTAssertEqual(retrievedLink, musapLink)
    }

    func testGetMusapId() {
        let musapLink = self.musapLink
        musapStorage.storeLink(link: musapLink)

        let retrievedId = musapStorage.getMusapId()
        
        XCTAssertEqual(retrievedId, musapLink.getMusapId())
    }

    func testRemoveLink() {
        let musapLink = self.musapLink
        musapStorage.storeLink(link: musapLink)

        musapStorage.removeLink()
        
        let retrievedLink = musapStorage.getMusaplink()
        XCTAssertNil(retrievedLink)
    }

    // ... Additional tests as needed ...
}
