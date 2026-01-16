//
//  BottomRegisterSwitch.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

struct BottomRegisterSwitch: View {
    var body: some View {
        
        VStack {
            HStack {
                Text("Don't have an account?")
                    .foregroundStyle(.gray)
                    .font(.callout)
                    .bold()
                
                NavigationLink() {
                    RegisterView()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    Text("Create an Account")
                        .foregroundStyle(.purplePrimary)
                        .font(.callout)
                        .bold()
                }
                
            }
            .padding()
        }
    }
}

#Preview {
    BottomRegisterSwitch()
}
