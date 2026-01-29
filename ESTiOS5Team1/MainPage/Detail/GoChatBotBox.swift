//
//  SwiftUIView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/28/26.
//

import SwiftUI

struct GoChatBotBox: View {
    @Binding var showRoot: Bool
    var body: some View {
        Button { showRoot = true }
        label: {
            HStack {
                Image(systemName: "book")
                Text("게임의 정보가 더 궁금하다면 챗봇에게 물어보세요.")
                    .foregroundStyle(.textPrimary)
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 37/255, green: 37/255, blue: 57/255))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.gray.opacity(0.6), lineWidth: 1)
            )
        }
    }
}

// #Preview {
//    SwiftUIView()
// }
