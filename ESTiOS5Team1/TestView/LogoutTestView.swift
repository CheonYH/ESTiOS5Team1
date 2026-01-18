//
//  LogoutTestView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import SwiftUI

/// 로그아웃 동작을 수동으로 테스트하기 위한 임시 화면입니다.
///
/// - Purpose:
///     `AuthViewModel.logout()` 호출 시 App 상태 전환이 올바르게 동작하는지 확인합니다.
/// - Important:
///     실제 제품에서는 해당 화면이 포함되지 않을 수 있습니다.
struct LogoutTestView: View {

    // MARK: - Properties

    /// 전역 앱 상태(로그인/로그아웃)를 제어하기 위한 AppViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    /// 인증 로직을 담당하는 ViewModel (테스트 목적의 로컬 인스턴스)
    @StateObject private var authViewModel = AuthViewModel(service: AuthServiceImpl())

    // MARK: - Body
    var body: some View {

        Button {
            // 로그아웃 실행 → 토큰 삭제 + App 상태를 signedOut으로 전환
            authViewModel.logout(appViewModel: appViewModel)

        } label: {
            Text("Log Out")
                .foregroundStyle(.black)
                .padding(10)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.yellow)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.gray.opacity(0.6), lineWidth: 1)
        )

    }
}

#Preview {
    LogoutTestView()
}
