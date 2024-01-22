//
//  YubiKeyConnection.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 30.11.2023.
//

import Foundation
import YubiKit

public class YubiKeyConnection: NSObject {
    
    public var accessoryConnection: YKFAccessoryConnection?
    public var nfcConnection: YKFNFCConnection?
    public var connectionCallback: ((_ connection: YKFConnectionProtocol) -> Void)?
    
    public override init() {
        super.init()
        YubiKitManager.shared.delegate = self
        YubiKitManager.shared.startAccessoryConnection()
    }
    
    public func connection(completion: @escaping (_ connection: YKFConnectionProtocol) -> Void) {
        if let connection = accessoryConnection {
            completion(connection)
        } else {
            connectionCallback = completion
            YubiKitManager.shared.startNFCConnection()
        }
    }
}

extension YubiKeyConnection: YKFManagerDelegate {
    public func didConnectNFC(_ connection: YKFNFCConnection) {
       nfcConnection = connection
        if let callback = connectionCallback {
            callback(connection)
        }
    }
    
    public func didDisconnectNFC(_ connection: YKFNFCConnection, error: Error?) {
        nfcConnection = nil
    }
    
    public func didConnectAccessory(_ connection: YKFAccessoryConnection) {
        accessoryConnection = connection
    }
    
    public func didDisconnectAccessory(_ connection: YKFAccessoryConnection, error: Error?) {
        accessoryConnection = nil
    }
}
