//
//  CoupleTask.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 15.1.2024.
//

import Foundation

public class CoupleTask {
    
    func couple(link: MusapLink, couplingCode: String, appId: String) async throws -> RelyingParty {
        do {
            let rp = try await link.couple(couplingCode: couplingCode, musapId: appId)

            let musapStorage = MusapStorage()
            musapStorage.storeRelyingParty(rp: rp)

            return rp
        } catch {
            AppLogger.shared.log("Error while coupling: \(error)")
            throw MusapError.internalError
        }
    }
    
}

