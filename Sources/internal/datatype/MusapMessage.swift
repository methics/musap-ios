//
//  MusapMessage.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 24.11.2023.
//

import Foundation

/// Message between the MUSAP library and MUSAP link
public class MusapMessage: Codable {
    
    public var payload:   String?
    public var musapid:   String?
    public var type:      String?
    public var uuid:      String?
    public var transid:   String?
    public var requestid: String?
    public var mac:       String?
    public var iv:        String?
    
    public init(payload:   String,
         musapid:   String,
         type:      String,
         uuid:      String,
         transid:   String,
         requestid: String,
         mac:       String,
         iv:        String
    ) {
        self.payload = payload
        self.musapid = musapid
        self.type = type
        self.uuid = uuid
        self.transid = transid
        self.requestid = requestid
        self.mac = mac
        self.iv = iv
    }
    
    init() {
        
    }

    
}
