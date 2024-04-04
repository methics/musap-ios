import XCTest
@testable import musap_ios

class SscdSearchReqTests: XCTestCase {

    func testInitialization() {
        let sscdType = "type1"
        let country = "country1"
        let provider = "provider1"
        let sscdId = "id1"
        let algorithm = KeyAlgorithm.ECC_P256_R1

        let searchReq = SscdSearchReq(sscdType: sscdType, country: country, provider: provider, sscdId: sscdId, algorithm: algorithm)

        XCTAssertEqual(searchReq.sscdType, sscdType)
        XCTAssertEqual(searchReq.country, country)
        XCTAssertEqual(searchReq.provider, provider)
        XCTAssertEqual(searchReq.sscdId, sscdId)
        XCTAssertEqual(searchReq.algorithm, algorithm)
    }

    func testMatchesWithMatchingSscd() {
        let sscdType = "type1"
        let country = "country1"
        let provider = "provider1"
        let algorithm = KeyAlgorithm.ECC_P256_R1
        let searchReq = SscdSearchReq(sscdType: sscdType, country: country, provider: provider, algorithm: algorithm)

        let sscd = SscdInfo(sscdName: "TestSscd", sscdType: sscdType, country: country, provider: provider, keygenSupported: false, algorithms: [KeyAlgorithm.ECC_P256_R1], formats: [SignatureFormat.RAW])
        
        XCTAssertTrue(searchReq.matches(sscd: sscd))
    }

    func testMatchesWithNonMatchingSscd() {
        let algorithm = KeyAlgorithm.ECC_P256_R1
        let searchReq = SscdSearchReq(sscdType: "SomeSscd", country: "SE", provider: "Yubikey", algorithm: algorithm)

        let sscd = SscdInfo(sscdName: "TestSscd", sscdType: "SecureEnclave", country: "FI", provider: "Apple", keygenSupported: false, algorithms: [KeyAlgorithm.RSA_2K], formats: [SignatureFormat.CMS])        
        XCTAssertFalse(searchReq.matches(sscd: sscd))
    }

    func testMatchesWithNilFields() {
        let searchReq = SscdSearchReq()

        let sscd = SscdInfo(sscdName: "", sscdType: "", country: "", provider: "", keygenSupported: true, algorithms: [KeyAlgorithm.ECC_P256_K1], formats: [SignatureFormat.RAW])
        XCTAssertFalse(searchReq.matches(sscd: sscd))
    }

    // ... Additional tests as needed ...
}
