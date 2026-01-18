//
//  BottomLoginSwitch.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

/// 회원가입 화면 하단의 로그인 전환 섹션입니다.
///
/// - Purpose:
///     이미 계정이 있는 사용자를 로그인 화면으로 유도합니다.
/// - Parameters:
///     - dismiss: 상위 화면으로 복귀하는 액션(예: 로그인 화면으로 돌아가기)
struct BottomLoginSwitch: View {
    // MARK: - Properties

    /// 상위에서 주입되는 화면 닫기 액션
    let dismiss: () -> Void

    // MARK: - Body

    var body: some View {
        HStack {
            Text("이미 계정이 있으신가요?")
                .foregroundStyle(.gray)
                .font(.callout)
                .bold()


            Button {
                dismiss()
            } label: {
                Text("로그인 하기")
                    .foregroundStyle(.purplePrimary)
                    .font(.callout)
                    .bold()
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    let toast = ToastManager()
    let auth = AuthServiceImpl()
    let appVM = AppViewModel(authService: auth, toast: toast)

    RegisterView()
        .environmentObject(appVM)
        .environmentObject(toast)
}


