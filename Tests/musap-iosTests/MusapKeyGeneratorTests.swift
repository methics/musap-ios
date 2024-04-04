//
//  MusapKeyGeneratorTests.swift
//  
//
//  Created by Teemu Mänttäri on 4.4.2024.
//

import XCTest
import musap_ios

final class MusapKeyGeneratorTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // This test needs real device or keychain access for simulators
    func testHkdfStatic_Success() {
        do {
            let base64KeyString = try MusapKeyGenerator.hkdfStatic(false)
            XCTAssertNotNil(base64KeyString, "The base64KeyString should not be nil")
            // Additional checks can be done on the base64KeyString for length or format.
        } catch {
            XCTFail("hkdfStatic should not throw an error for the success scenario.")
            print(error)
        }
    }

}
