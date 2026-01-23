//
//  BottomRegisterSwitch.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

/// 로그인 화면 하단의 회원가입 전환 섹션입니다.
///
/// - Purpose:
///     계정이 없는 사용자를 회원가입 화면으로 유도합니다.
/// - Navigation:
///     `NavigationLink`를 통해 `RegisterView`로 이동합니다.
struct BottomRegisterSwitch: View {
    // MARK: - Body
    var body: some View {

        VStack {
            HStack {
                Text("아직 계정이 없으신가요?")
                    .foregroundStyle(.gray)
                    .font(.caption)
                    .bold()

                NavigationLink {
                    RegisterView()
                } label: {
                    Text("계정을 생성하세요")
                        .foregroundStyle(.purplePrimary)
                        .font(.caption)
                        .bold()
                }

            }
            .padding()
        }
    }
}

#Preview {
    let toast = ToastManager()
    let auth = AuthServiceImpl()
    let appVM = AppViewModel(authService: auth, toast: toast)

    LoginView()
        .environmentObject(appVM)
        .environmentObject(toast)
}
