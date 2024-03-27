//
//  File.swift
//  
//
//  Created by Teemu Mänttäri on 27.3.2024.
//

import Foundation

public class UiccKeyAttestation: CertificateKeyAttestation {
    
    /**
     * UICC specific certificate-based key attestation.
     * This assumes that the MNO and CA have performed registration operations that verify
     * that the user's private key is kept in an applet inside the UICC.
     */
    public override func getAttestationType() -> String {
        return KeyAttestationType.UICC
    }
}
