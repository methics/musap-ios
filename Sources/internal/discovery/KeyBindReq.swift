//
//  KeyBindReq.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public class KeyBindReq {
    
    private var keyAlias: String
    private var did: String
    private var role: String
    private var stepUpPolicy: StepUpPolicy
    private var attributes: [KeyAttribute]
    private var generateNewKey: Bool
    private var displayText: String
    
    public init(
        keyAlias:       String,
        did:            String,
        role:           String,
        stepUpPolicy:   StepUpPolicy,
        attributes:     [KeyAttribute],
        generateNewKey: Bool = false,
        displayText: String
    )
    {
        self.keyAlias = keyAlias
        self.did = did
        self.role = role
        self.stepUpPolicy = stepUpPolicy
        self.attributes = attributes
        self.generateNewKey = generateNewKey
        self.displayText = displayText
    }
    
    public func addAttribute(key: String, value: String) -> Void {
        let keyAttribute = KeyAttribute(name: key, value: value)
        self.attributes.append(keyAttribute)
    }
    
    public func addAttribute(attribute: KeyAttribute) {
        self.attributes.append(attribute)
    }
    
    public func getAttributes() -> [KeyAttribute] {
        return self.attributes
    }
    
    public func getAttribute(name: String) -> String? {
        for attribute in self.getAttributes() {
            if name == attribute.name {
                guard let attrValue = attribute.value else {
                    return nil
                }
                return attrValue
            }
        }
        return nil
    }
    
    public func getKeyAlias() -> String {
        return self.keyAlias
    }
    
    /**
     * Get the text to display to the user during the signature request
     * @return Display text (a.k.a. DTBD). Default is "Sign with MUSAP".
     */
    public func getDisplayText() -> String {
        return self.displayText
    }
    
}


