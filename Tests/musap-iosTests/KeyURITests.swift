import XCTest
import musap_ios
@testable import musap_ios

class KeyURITests: XCTestCase {
    
    
    func testWithMusapKey() {
        let key = MusapKey(keyAlias: "KeyName", sscdType: "testSSCD", publicKey: PublicKey(publicKey: "ABC".data(using: .utf8)!), keyUri: KeyURI(keyUri: "keyuri:key?name=KeyName&sscd=TestSSCD&loa=TestLOA"))
        
        let uri = KeyURI(key: key)
        
        XCTAssertEqual(uri.getName(), "KeyName")
    }
    
    func testGetUri() {
        let params = ["name": "TestName", "sscd": "TestSSCD", "loa": "TestLOA"]
        let keyURI = KeyURI(params: params)
        let resultUri = keyURI.getUri()

        XCTAssertTrue(resultUri.hasPrefix("keyuri:key?"), "URI should start with the specified prefix.")
        
        for (key, value) in params {
            XCTAssertTrue(resultUri.contains("\(key)=\(value)"), "URI should contain the \(key)=\(value) pair.")
        }
    }
    
    func testMatches() {
        let uriString1 = "keyuri:key?name=TestName&sscd=TestSSCD&loa=TestLOA"
        let uriString2 = "keyuri:key?name=TestName&sscd=TestSSCD&loa=TestLOA"
        let keyURI1 = KeyURI(keyUri: uriString1)
        let keyURI2 = KeyURI(keyUri: uriString2)
        
        XCTAssertTrue(keyURI1.matches(keyUri: keyURI2))
    }
    
    func testPartialMatch() {
        let fullUriString = "keyuri:key?name=TestName&sscd=TestSSCD&loa=TestLOA"
        let partialUriString = "keyuri:key?name=TestName&loa=TestLOA"
        let fullKeyURI = KeyURI(keyUri: fullUriString)
        let partialKeyURI = KeyURI(keyUri: partialUriString)
        
        XCTAssertTrue(fullKeyURI.isPartialMatch(keyURI: partialKeyURI))
    }
    
    func testEquality() {
        let uriString1 = "keyuri:key?name=TestName&sscd=TestSSCD&loa=TestLOA"
        let uriString2 = "keyuri:key?name=TestName&sscd=TestSSCD&loa=TestLOA"
        let keyURI1 = KeyURI(keyUri: uriString1)
        let keyURI2 = KeyURI(keyUri: uriString2)
        
        XCTAssertEqual(keyURI1, keyURI2)
    }
    
    func testHashable() {
        let uriString = "keyuri:key?name=TestName&sscd=TestSSCD&loa=TestLOA"
        let keyURI = KeyURI(keyUri: uriString)
        
        var hashSet = Set<KeyURI>()
        hashSet.insert(keyURI)
        
        XCTAssertTrue(hashSet.contains(keyURI))
    }
    
    // Add more tests for failure cases, nil handling, and other edge cases as necessary
    
}
