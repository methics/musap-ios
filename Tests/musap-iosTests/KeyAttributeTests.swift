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

    
    func testValueDataConversion() {
        let name = "testName"
        let originalString = "testValue"
        guard let originalData = originalString.data(using: .utf8) else {
            XCTFail("Could not create data from test string.")
            return
        }
        let base64String = originalData.base64EncodedString()
        
        let attribute = KeyAttribute(name: name, value: base64String)
        
        let decodedData = attribute.getValueData()
        XCTAssertEqual(decodedData, originalData)
        
        let decodedString = String(data: decodedData!, encoding: .utf8)
        XCTAssertEqual(decodedString, originalString)
    }
    
    // ... Other tests for different scenarios and edge cases ...
}
