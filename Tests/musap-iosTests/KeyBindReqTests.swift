import XCTest
@testable import musap_ios

class KeyBindReqTests: XCTestCase {
    
    func testKeyBindReqInitialization() {
        let keyAlias = "testAlias"
        let did = "testDid"
        let role = "testRole"
        let stepUpPolicy = StepUpPolicy() // Assuming StepUpPolicy has a default initializer
        let attributes = [KeyAttribute(name: "attr1", value: "value1")]
        let generateNewKey = true
        let displayText = "Test Display Text"

        let keyBindReq = KeyBindReq(
            keyAlias: keyAlias,
            did: did,
            role: role,
            stepUpPolicy: stepUpPolicy,
            attributes: attributes,
            generateNewKey: generateNewKey,
            displayText: displayText
        )

        XCTAssertEqual(keyBindReq.getKeyAlias(), keyAlias)
        XCTAssertEqual(keyBindReq.getAttributes().count, 1)
        XCTAssertEqual(keyBindReq.getAttributes().first?.name, "attr1")
        XCTAssertEqual(keyBindReq.getDisplayText(), displayText)
    }

    func testAddAttribute() {
        let keyBindReq = KeyBindReq(
            keyAlias: "testAlias",
            did: "testDid",
            role: "testRole",
            stepUpPolicy: StepUpPolicy(),
            attributes: [],
            displayText: "Test Display Text"
        )

        keyBindReq.addAttribute(key: "newAttr", value: "newValue")
        XCTAssertEqual(keyBindReq.getAttributes().count, 1)
        XCTAssertEqual(keyBindReq.getAttributes().first?.name, "newAttr")
        XCTAssertEqual(keyBindReq.getAttributes().first?.value, "newValue")
    }

    func testGetAttribute() {
        let attributes = [KeyAttribute(name: "attr1", value: "value1"), KeyAttribute(name: "attr2", value: "value2")]
        let keyBindReq = KeyBindReq(
            keyAlias: "testAlias",
            did: "testDid",
            role: "testRole",
            stepUpPolicy: StepUpPolicy(),
            attributes: attributes,
            displayText: "Test Display Text"
        )

        let attrValue = keyBindReq.getAttribute(name: "attr2")
        XCTAssertEqual(attrValue, "value2")
    }

    func testGetAttributeNotExist() {
        let attributes = [KeyAttribute(name: "attr1", value: "value1")]
        let keyBindReq = KeyBindReq(
            keyAlias: "testAlias",
            did: "testDid",
            role: "testRole",
            stepUpPolicy: StepUpPolicy(),
            attributes: attributes,
            displayText: "Test Display Text"
        )

        let attrValue = keyBindReq.getAttribute(name: "nonExistingAttr")
        XCTAssertNil(attrValue)
    }
    
    // ... Additional tests as needed ...
}
