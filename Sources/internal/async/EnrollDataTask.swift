//
//  EnrollDataTask.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 11.1.2024.
//

import Foundation

public class EnrollDataTask {
    
    private let link:     MusapLink
    private let apnsToken: String?
    
    init(link: MusapLink, apnsToken: String?) {
        self.link = link
        self.apnsToken = apnsToken
    }
    
    func enrollData() async throws -> MusapLink {
        do {
            let link: MusapLink = try await self.link.enroll(apnsToken: self.apnsToken)
            MusapStorage().storeLink(link: link)
            return link
        } catch {
            throw MusapError.internalError
        }
    }
    
}
