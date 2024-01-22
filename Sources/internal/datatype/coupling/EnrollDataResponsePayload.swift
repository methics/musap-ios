//
//  EnrollDataResponsePayload.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 12.1.2024.
//

import Foundation

public class EnrollDataResponsePayload: Decodable {
    
    public let musapid: String?
    
    init(musapid: String?) {
        self.musapid = musapid
    }
    
}
