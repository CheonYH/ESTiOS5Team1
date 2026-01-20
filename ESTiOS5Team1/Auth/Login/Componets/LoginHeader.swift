//
//  LoginHeader.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

/// 로그인 화면 상단 헤더 영역입니다.
///
/// - Composition:
///     앱 로고/타이틀과 환영 문구를 표시합니다.
/// - Important:
///     화면 배경 및 색상은 상위 View에서 결정합니다.
struct LoginHeader: View {
    // MARK: - Body
    var body: some View {
        VStack(spacing: 10) {

            Image(systemName: "gamecontroller.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.purplePrimary)
                .frame(width: 44, height: 44)

            Text("GameCompass")
                .font(.system(size: 48))
                .bold()
                .foregroundStyle(.white)

            Text("게임 리뷰·추천·정보를 한 곳에서")
                .font(.title3)
                .bold()
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)

        VStack(alignment: .leading, spacing: 10) {
            Text("환영합니다")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(.white)

            Text("로그인하고 당신만의 여정을 시작하세요")
                .font(.title3)
                .bold()
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .padding(10)
    }
}

// MARK: - Preview

#Preview {
    let toast = ToastManager()
    let auth = AuthServiceImpl()
    let appVM = AppViewModel(authService: auth, toast: toast)

    LoginView()
        .environmentObject(appVM)
        .environmentObject(toast)
}
