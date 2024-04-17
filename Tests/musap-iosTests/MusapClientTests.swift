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
        
        let keys = MusapClient.listKeys()
        let storage = MetadataStorage()
        for key in keys {
            let _ = storage.removeKey(key: key)
        }
    }

    func testListEnabledSscds() throws {
        let enabled = MusapClient.listEnabledSscds()
        
        XCTAssertNotNil(enabled)
        XCTAssertEqual(enabled?.count, 2)
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
        let before = MusapClient.listEnabledSscds()
        
        let sscd = YubikeySscd()
        MusapClient.enableSscd(sscd: sscd, sscdId: "yubikey")
        
        let enabled = MusapClient.listEnabledSscds()
        XCTAssertNotNil(enabled)
        XCTAssertNotEqual(before!.count, enabled!.count)
    }
    
    func testIsLinkEnabledWhenNot() {
        let result = MusapClient.isLinkEnabled()
        
        XCTAssertFalse(result)
    }
    
    func testGetMusapIdWhenNotAvailable() {
        let result = MusapClient.getMusapId()
        XCTAssertNil(result)
    }
    
    func testRemoveSscd() {
        self.addKeyToSscd()
        
        let activeSscds = MusapClient.listActiveSscds()
        let before = activeSscds.count
        print("Amount of SSCDs before remove: \(before)")
        guard let sscdInfo = activeSscds.first?.getSscdInfo() else {
            XCTFail()
            return
        }
        
        print("TEST: Trying to remove \(sscdInfo.getSscdName())")
        let result = MusapClient.removeSscd(musapSscd: sscdInfo)
        
        XCTAssertTrue(result)
        
        let afterRemoveList = MusapClient.listActiveSscds() 
        
        XCTAssertNotEqual(afterRemoveList.count, before)
        
    }
    
    func addKeyToSscd() {
        guard let keyData = "12345".data(using: .utf8) else {
            return
        }
        
        let uri = KeyURI(keyUri: "keyuri:key?name=KeyName&sscd=TestSSCD&loa=TestLOA")
        let key = MusapKey(keyAlias: "MusapClientKey", keyId: "12345", sscdType: "SE", publicKey: PublicKey(publicKey: keyData), keyUri: uri)
        
        guard let sscd = MusapClient.listEnabledSscds() else {
            return
        }
        
        let someSscd = sscd.first
        
        do {
            try MetadataStorage().addKey(key: key, sscd: (someSscd?.getSscdInfo())!)
        } catch {
            return
        }
        
    }
    

}
