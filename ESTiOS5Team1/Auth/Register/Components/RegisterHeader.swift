//
//  RegisterHeader.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

/// 회원가입 화면 상단 헤더 영역입니다.
///
/// - Purpose:
///     뒤로 가기 버튼과 헤더 타이틀/설명을 제공합니다.
/// - Parameters:
///     - dismiss: 상위 화면으로 복귀하는 액션(예: 로그인 화면으로 돌아가기)
struct RegisterHeader: View {
    // MARK: - Properties

    /// 상위에서 주입되는 화면 닫기 액션
    let dismiss: () -> Void

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 12) {

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .padding(Spacing.pv10)
                        .background(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                }

                Text("계정 생성")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.white)
            }

            Text("지금 가입하고 당신만의 여정을 시작하세요")
                .font(.title3)
                .bold()
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .padding(.leading, 10)
        .padding(.trailing, 10)
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
