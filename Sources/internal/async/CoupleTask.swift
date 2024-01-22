//
//  CoupleTask.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 15.1.2024.
//

import Foundation

import Foundation

class CoupleTask {
    
    func couple(link: MusapLink, couplingCode: String, appId: String) async throws -> RelyingParty {
        do {
            let rp = try await link.couple(couplingCode: couplingCode, musapid: appId)

            let musapStorage = MusapStorage()
            musapStorage.storeRelyingParty(rp: rp)

            return rp
        } catch {
            print("Error while coupling: \(error)")
            throw MusapError.internalError
        }
    }
    
}

