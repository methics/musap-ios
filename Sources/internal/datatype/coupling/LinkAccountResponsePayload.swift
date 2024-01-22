//
//  LinkAccountResponsePayload.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.1.2024.
//

import Foundation

public class LinkAccountResponsePayload: ResponsePayload {
    
    public let linkid: String
    public let name:   String
    
    init(linkid: String, name: String, status: String, errorCode: String?) {
        self.linkid = linkid
        self.name = name
        super.init(status: status, errorCode: errorCode)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let linkId = try container.decode(String.self, forKey: .linkid)
        let name = try container.decodeIfPresent(String.self, forKey: .name) ?? "defaultname" // Name requires a feature in the backend which is not available yet. For now, defaultname will serve us.
        let status = try container.decode(String.self, forKey: .status)
        let errorCode = try container.decodeIfPresent(String.self, forKey: .errorCode)
        
        self.linkid = linkId
        self.name = name
        
        super.init(status: status, errorCode: errorCode)
    }
    
    public func isSuccess() -> Bool {
        return self.status.lowercased() == "success"
    }
    
    private enum CodingKeys: String, CodingKey {
        case linkid
        case name
        case status
        case errorCode = "errorcode"
    }
    
}
