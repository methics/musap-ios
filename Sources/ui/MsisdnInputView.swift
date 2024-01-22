//
//  MsisdnInputView.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 11.1.2024.
//

import SwiftUI

struct MsisdnInputView: View {
    @State private var msisdn: String = ""
    var onMsisdnSubmit: ((String) -> Void)?
    
    var body: some View {
        VStack {
            Text("App needs your MSISDN")
                .fontWeight(.bold)
            TextField("Enter MSISDN", text: $msisdn)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Submit") {
                onMsisdnSubmit!(msisdn)
            }
            .padding()
        }
    }
}
