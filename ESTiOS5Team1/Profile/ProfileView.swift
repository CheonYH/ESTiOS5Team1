//
//  ProfileView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/23/26.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "person.fill")
                .padding()
                .background(.gray.opacity(0.3), in: Circle())
            Button("닉네임 변경") {
                // 닉네임 변경
            }

            Button("로그아웃") {
                // 로그아웃
            }
        }

    }
}

#Preview {
    ProfileView()
}
