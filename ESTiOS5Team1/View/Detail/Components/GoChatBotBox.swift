//
//  SwiftUIView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/28/26.
//

import SwiftUI

// MARK: - Go ChatBot Box

/// 상세 화면에서 챗봇 화면으로 이동하기 위한 CTA 박스입니다.
///
/// 외부에서 주입받은 `showRoot` 바인딩을 `true`로 변경하여
/// 네비게이션 목적지(예: `RootTabView`)로 이동하도록 트리거합니다.

struct GoChatBotBox: View {
    /// 루트(챗봇) 화면 전환 트리거
    ///
    /// 상위 뷰에서 `navigationDestination(isPresented:)`로 감지해 화면 전환에 사용합니다.
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
