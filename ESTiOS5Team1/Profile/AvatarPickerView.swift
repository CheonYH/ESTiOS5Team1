//
//  AvatarPickerView.swift
//  ESTiOS5Team1
//
//  Created by Codex on 1/30/26.
//

import SwiftUI
import Kingfisher

/// 프로필 아바타 이미지를 표시하는 공용 뷰입니다.
///
/// - URL이 유효하면 원격 이미지를 원형으로 렌더링합니다.
/// - URL이 없거나 실패하면 SF Symbol 기본 아이콘을 표시합니다.
struct AvatarPickerView: View {
    /// 서버에서 내려온 아바타 이미지 URL 문자열입니다.
    let avatarURLString: String
    /// 원형 아바타 전체 지름입니다.
    let avatarDiameter: CGFloat
    /// 기본 아이콘(placeholder) 크기입니다.
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
