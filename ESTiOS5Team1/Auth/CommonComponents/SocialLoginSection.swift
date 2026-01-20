//
//  SocialLoginSection.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

/// 소셜 로그인 버튼 섹션입니다.
///
/// - Purpose:
///     Apple/PlayStation/Xbox 등 소셜 로그인 진입 버튼을 보여줍니다.
/// - Note:
///     실제 소셜 로그인 연동은 추후 구현 예정이며, 현재는 UI만 제공합니다.
struct SocialLoginSection: View {
    // MARK: - Body
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

// MARK: - Preview
#Preview {
    SocialLoginSection()
}
