//
//  KeyAttribute.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation
import Security

public struct KeyAttribute: Codable {
    
    public var name: String
    public var value: String?
    
    init(name: String, value: String?) {
        self.name = name
        self.value = value
    }
    
    public init(name: String, cert: SecCertificate) {
        self.name = name
        self.value = certToBase64(cert: cert)
    }
    
    private func certToBase64(cert: SecCertificate) -> String? {
        if let derData = SecCertificateCopyData(cert) as Data? {
            return derData.base64EncodedString()
        }
        return nil
    }
    
    public func getName() -> String {
        return self.name
    }
    
    public func getValue() -> String? {
        guard let value = self.value else {
            return nil
        }
        
        return value
    }
    
    public func getValueData() -> Data? {
        guard let value = self.value,
              let valueAsData = value.data(using: .utf8)
        else {
            return nil
        }
        
        let valueB64 = valueAsData.base64EncodedData()
        return Data(base64Encoded: valueB64)

    }
    
    
}
