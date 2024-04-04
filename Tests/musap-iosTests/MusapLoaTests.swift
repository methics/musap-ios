import XCTest
@testable import musap_ios

class MusapLoaTests: XCTestCase {
    
    func testLoaInitialization() {
        let customLoa = MusapLoa(loa: "custom", number: 5, scheme: "Custom-Scheme")
        XCTAssertEqual(customLoa.getLoa(), "custom")
        XCTAssertEqual(customLoa.getScheme(), "Custom-Scheme")
    }
    
    func testLoaComparison() {
        XCTAssertTrue(MusapLoa.ISO_LOA4 > MusapLoa.ISO_LOA2)
        XCTAssertFalse(MusapLoa.EIDAS_LOW > MusapLoa.EIDAS_SUBSTANTIAL)
        XCTAssertEqual(MusapLoa.EIDAS_HIGH, MusapLoa(loa: MusapLoa.LOA_SCHEME_EIDAS, number: 4, scheme: MusapLoa.LOA_SCHEME_EIDAS))
    }
    
    func testCompareLoAFunction() {
        XCTAssertTrue(MusapLoa.compareLoA(first: MusapLoa.EIDAS_HIGH, second: MusapLoa.EIDAS_SUBSTANTIAL))
        XCTAssertFalse(MusapLoa.compareLoA(first: MusapLoa.EIDAS_LOW, second: MusapLoa.ISO_LOA3))
    }

    func testCompareLoAWithNil() {
        XCTAssertFalse(MusapLoa.compareLoA(first: nil, second: MusapLoa.ISO_LOA2))
        XCTAssertFalse(MusapLoa.compareLoA(first: MusapLoa.ISO_LOA2, second: nil))
    }

    // ... Additional tests as needed ...
}
