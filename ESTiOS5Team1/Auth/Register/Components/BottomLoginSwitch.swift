//
//  BottomLoginSwitch.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

struct BottomLoginSwitch: View {

    let dismiss: () -> Void
    
    var body: some View {
        HStack {
            Text("Already have an account?")
                .foregroundStyle(.gray)
                .font(.callout)
                .bold()


            Button {
                dismiss()
            } label: {
                Text("Login")
                    .foregroundStyle(.purplePrimary)
                    .font(.callout)
                    .bold()
            }
        }
        .padding()
    }
}


