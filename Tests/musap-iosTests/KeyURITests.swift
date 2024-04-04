import XCTest
import musap_ios
@testable import musap_ios

class KeyURITests: XCTestCase {
    
    func testInitWithNameSSCDAndLOA() {
        let name = "TestName"
        let sscd = "TestSSCD"
        let loa = "TestLOA"
        
        let keyURI = KeyURI(name: name, sscd: sscd, loa: loa)
        XCTAssertEqual(keyURI.getName(), name)
        XCTAssertEqual(keyURI.keyUriMap["sscd"], sscd)
        XCTAssertEqual(keyURI.keyUriMap["loa"], loa)
    }
    
    func testInitWithUriString() {
        let uriString = "keyuri:key?name=TestName&sscd=TestSSCD&loa=TestLOA"
        let keyURI = KeyURI(keyUri: uriString)
        
        XCTAssertEqual(keyURI.getName(), "TestName")
        XCTAssertEqual(keyURI.keyUriMap["sscd"], "TestSSCD")
        XCTAssertEqual(keyURI.keyUriMap["loa"], "TestLOA")
    }
    
    func testGetUri() {
        let params = ["name": "TestName", "sscd": "TestSSCD", "loa": "TestLOA"]
        let keyURI = KeyURI(params: params)
        let expectedUri = "keyuri:key?name=TestName&sscd=TestSSCD&loa=TestLOA"
        
        XCTAssertEqual(keyURI.getUri(), expectedUri)
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
