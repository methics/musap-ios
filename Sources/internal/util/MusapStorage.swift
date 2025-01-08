//
//  MusapStorage.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 9.1.2024.
//

import Foundation

public class MusapStorage {
    
    private static let PREF_NAME     = "musap_internal"
    private static let MUSAP_ID_PREF = "musapid"
    private static let RP_PREF       = "relying-parties"
    
    
    /**
     Stores a relying party
     */
    public func storeRelyingParty(rp: RelyingParty) -> Void {
        AppLogger.shared.log("Trying to store a relying party with linkID:  (\(rp.getLinkId()))")

        var rpList = self.listRelyingParties()
        
        if rpList == nil {
            rpList = [RelyingParty]()
            rpList?.append(rp)
        } else {
            rpList?.append(rp)
        }
        
        let encoder = JSONEncoder()
        do {
            let jsonStr = try encoder.encode(rpList).base64EncodedString()
            self.storePrefValue(prefName: MusapStorage.RP_PREF, prefValue: jsonStr)
        } catch {
            AppLogger.shared.log("Failed to store a relying party: \(error)", .error)
        }
        
    }
    
    public func removeRelyingParty(rp: RelyingParty) -> Bool {
        var removed = false
        
        var newRps = [RelyingParty]()
        
        if var oldRps = listRelyingParties() {
            for oldRp in oldRps {
                
                let linkId = oldRp.getLinkId().lowercased()
                if linkId == rp.getLinkId().lowercased() {
                    removed = true
                } else {
                    newRps.append(oldRp)
                }

            }
            
            let encoder = JSONEncoder()
            do {
                let jsonStr = try encoder.encode(newRps).base64EncodedString()
                self.storePrefValue(prefName: MusapStorage.RP_PREF, prefValue: jsonStr)
            } catch {
                AppLogger.shared.log("Failed to decrypt: \(error)")
            }
            
        }
        
        return removed
        
    }
    
    public func removeLink() -> Void {
        UserDefaults.standard.removeObject(forKey: MusapStorage.MUSAP_ID_PREF)
    }
    
    public func listRelyingParties() -> [RelyingParty]? {
        guard let base64Json = self.getPrefValue(prefName: MusapStorage.RP_PREF) else {
            return nil
        }
        
        guard let jsonData = Data(base64Encoded: base64Json) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        do {
            let relyingParties = try decoder.decode([RelyingParty].self, from: Data(jsonData))
            return relyingParties
        } catch {
            AppLogger.shared.log("Failed to decode JSON to relying party: \(error)", .error)
            return nil
        }
        
    }
    
    /**
     Store the MUSAP Link
     */
    public func storeLink(link: MusapLink) -> Void {
        AppLogger.shared.log("Trying to store MUSAP Link...")
        
        guard let musapId = link.getMusapId() else {
            print("Error storing MusapLink: missing Musap ID")
            AppLogger.shared.log("Failed to store MUSAP Link, missing MUSAP ID", .error)
            return
        }
        
        let encoder = JSONEncoder()
        
        do {
            let jsonStringBase64 = try encoder.encode(link).base64EncodedString()
            self.storePrefValue(prefName: MusapStorage.MUSAP_ID_PREF, prefValue: jsonStringBase64)
            AppLogger.shared.log("Stored link with MUSAP ID: \(musapId)")
        } catch {
            AppLogger.shared.log("Unable to encode MusapLink to JSON string", .error)
        }
        
    }
    
    public func getMusaplink() -> MusapLink? {
        guard let prefValue = self.getPrefValue(prefName: MusapStorage.MUSAP_ID_PREF),
            let jsonData = Data(base64Encoded: prefValue)
        else {
            return nil
        }
        
        let decoder = JSONDecoder()
        
        do {
            let musapLink = try decoder.decode(MusapLink.self, from: jsonData)
            return musapLink
        } catch {
            AppLogger.shared.log("Failed to get MUSAP Link: \(error)")
            return nil
        }
    }
    
    public func getMusapId() -> String? {
        guard let link = self.getMusaplink() else {
            return nil
        }
        
        return link.getMusapId()
    }
    
    private func storePrefValue(prefName: String, prefValue: String) -> Void {
        UserDefaults.standard.setValue(prefValue, forKey: prefName)
    }
    
    private func getPrefValue(prefName: String) -> String? {
        guard let value = UserDefaults.standard.string(forKey: prefName) else {
            return nil
        }
        return value
    }
    
}
