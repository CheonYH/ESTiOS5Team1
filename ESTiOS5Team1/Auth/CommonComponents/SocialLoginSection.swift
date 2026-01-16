//
//  SocialLoginSection.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

struct SocialLoginSection: View {
    var body: some View {
        HStack(spacing: 16) {
            Button {

            } label: {
                Image(systemName: "applelogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .padding(12)
                    .frame(width: 120, height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                    .foregroundStyle(.white)
            }

            Button {

            } label: {
                Image(systemName: "playstation.logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .padding(12)
                    .frame(width: 120, height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                    .foregroundStyle(.white)
            }

            Button {

            } label: {
                Image(systemName: "xbox.logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .padding(12)
                    .frame(width: 120, height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                    .foregroundStyle(.white)
            }

        }
    }
}

#Preview {
    SocialLoginSection()
}
