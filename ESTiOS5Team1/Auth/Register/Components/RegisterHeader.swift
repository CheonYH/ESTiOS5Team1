//
//  RegisterHeader.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

struct RegisterHeader: View {
    let dismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 12) {

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .padding(Spacing.pv10)
                        .background(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                }

                Text("Create Account")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.white)
            }

            Text("Join the gaming community today")
                .font(.title3)
                .bold()
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .padding(.leading, 10)
        .padding(.trailing, 10)
    }
}

#Preview {
    RegisterView()
}
