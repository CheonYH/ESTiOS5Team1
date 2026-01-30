//
//  AvatarPickerView.swift
//  ESTiOS5Team1
//
//  Created by Codex on 1/30/26.
//

import SwiftUI
import Kingfisher

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
