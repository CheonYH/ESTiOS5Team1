//
//  AvatarPickerView.swift
//  ESTiOS5Team1
//
//  Created by Codex on 1/30/26.
//

import SwiftUI
import Kingfisher

/// 프로필 아바타 렌더링 뷰입니다.
///
/// - Parameters:
///   - avatarURLString: 서버에서 받은 아바타 URL 문자열
///   - avatarDiameter: 아바타 원의 전체 지름
///   - avatarSize: 기본 아이콘 크기
struct AvatarPickerView: View {
    let avatarURLString: String
    let avatarDiameter: CGFloat
    let avatarSize: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(.gray.opacity(0.3))
                .overlay(
                    Circle()
                        .stroke(.purplePrimary.opacity(0.8), lineWidth: 2)
                )
                .shadow(color: .purplePrimary.opacity(0.6), radius: 18)

            if let url = URL(string: avatarURLString), url.scheme == "https" {
                KFImage(url)
                    .placeholder {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.purplePrimary)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: avatarDiameter, height: avatarDiameter)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.purplePrimary)
                    .frame(width: avatarSize, height: avatarSize)
            }
        }
        .frame(width: avatarDiameter, height: avatarDiameter)
    }
}

#Preview {
    AvatarPickerView(
        avatarURLString: "",
        avatarDiameter: 120,
        avatarSize: 48
    )
    .background(.black)
}
