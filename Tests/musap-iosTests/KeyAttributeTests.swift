import XCTest
@testable import musap_ios

class KeyAttributeTests: XCTestCase {
    
    func testInitWithNameAndValue() {
        let name = "testName"
        let value = "testValue"
        let attribute = KeyAttribute(name: name, value: value)
        
        XCTAssertEqual(attribute.getName(), name)
        XCTAssertEqual(attribute.getValue(), value)
        XCTAssertNotNil(attribute.getValueData())
    }
    
    func testInitWithNameAndNilValue() {
        let name = "testName"
        let attribute = KeyAttribute(name: name, value: nil)
        
        XCTAssertEqual(attribute.getName(), name)
        XCTAssertNil(attribute.getValue())
        XCTAssertNil(attribute.getValueData())
    }

}
