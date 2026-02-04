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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Body
    var body: some View {
        let isRegularWidth = horizontalSizeClass == .regular
        let logoWidth: CGFloat = isRegularWidth ? 360 : 310

        VStack(spacing: 0) {
            Image("mainLogo")
                .resizable()
                .scaledToFit()
                .frame(width: logoWidth)
                .padding(.top, Spacing.pv10)
                .padding(.bottom, -35)

        }
        .frame(maxWidth: .infinity)

        VStack(alignment: .leading, spacing: Spacing.pv10) {
            Text("환영합니다")
                .font(.title2)
                .bold()
                .foregroundStyle(.white)

            Text("로그인하고 당신만의 여정을 시작하세요")
                .font(.headline)
                .bold()
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .padding(Spacing.pv10)
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
