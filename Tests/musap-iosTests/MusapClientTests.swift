//
//  MusapClientTests.swift
//  
//
//  Created by Teemu Mänttäri on 4.4.2024.
//

import XCTest
import musap_ios

final class MusapClientTests: XCTestCase {

    override func setUp() {
        let sscd = SecureEnclaveSscd()
        MusapClient.enableSscd(sscd: SecureEnclaveSscd(), sscdId: "123")
    }

    func testListEnabledSscds() throws {
        let enabled = MusapClient.listEnabledSscds()
        
        XCTAssertNotNil(enabled)
        XCTAssertEqual(enabled?.count, 1)
    }
    
    func testListEnabledSscdsWithSearchReq() {
        let req = SscdSearchReq(sscdType: "SE")
        let enabled: [MusapSscd]? = MusapClient.listEnabledSscds(req: req)
        
        XCTAssertNotNil(enabled)
    }
    
    func testListKeysWithNoKeys() {
        let keys = MusapClient.listKeys()
        
        XCTAssertNotNil(keys)
        XCTAssertEqual(keys.count, 0)
    }
    
    func testEnableAnotherSscd() {
        let sscd = KeychainSscd()
        MusapClient.enableSscd(sscd: sscd, sscdId: "keychain")
        
        let enabled = MusapClient.listEnabledSscds()
        XCTAssertNotNil(enabled)
        XCTAssertEqual(enabled?.count, 2)
    }
    
    func testIsLinkEnabledWhenNot() {
        let result = MusapClient.isLinkEnabled()
        
        XCTAssertFalse(result)
    }
    
    func testGetMusapIdWhenNotAvailable() {
        let result = MusapClient.getMusapId()
        XCTAssertNil(result)
    }
    
    func testGenerateKey() async {
        
        let keygenreq = KeyGenReq(keyAlias: "testkey", role: "personal")
        let enabled = MusapClient.listEnabledSscds()
        
        let sscd = (enabled?.first)!
        
        await MusapClient.generateKey(sscd: sscd, req: keygenreq) { result in
            
            switch result {
            case .success(let key):
                XCTAssertNotNil(key.getKeyId())
                
                let keysAmount = MusapClient.listKeys()
                XCTAssertEqual(keysAmount.count, 1)
                
            case .failure(let error):
                print("error")
            }
        }
        
    }

}
