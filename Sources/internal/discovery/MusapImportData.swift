//
//  MusapImportData.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 20.11.2023.
//

import Foundation

public class MusapImportData: Codable {
    
    public var sscds: [SscdInfo]?
    public var keys:  [MusapKey]?
    
    public init(sscds: [SscdInfo], keys: [MusapKey]) {
        self.sscds = sscds
        self.keys = keys
    }
    
    public init() {}
    
    public func toJson() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let jsonData = try encoder.encode(self)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            AppLogger.shared.log("Error encoding data: \(error)")
            return nil
        }
    }
    
    public static func fromJson(jsonString: String) -> MusapImportData? {
        AppLogger.shared.log("Trying to turn JSON into MusapImportData object")
        let decoder = JSONDecoder()
        if let jsonData = jsonString.data(using: .utf8) {
            do {
                let data = try decoder.decode(MusapImportData.self, from: jsonData)
                return data
            } catch {
                AppLogger.shared.log("Failed to decode expected JSON to MusapImportData: \(error)")
                return nil
            }
        }
        AppLogger.shared.log("Failed to decode expected JSON to MusapImportData", .error)
        return nil
    }

    
}
