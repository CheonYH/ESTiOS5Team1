//
//  RegisterView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

//
//  RegisterTestView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import SwiftUI

/// 회원가입 화면입니다.
///
/// - Composition:
///     `RegisterHeader`, `RegisterForm`, `SocialLoginSection`, `BottomLoginSwitch`로 구성됩니다.
/// - State Management:
///     `ToastManager`를 overlay로 구독하여 회원가입 결과를 Toast로 표시합니다.
/// - Navigation:
///     `dismiss()`를 통해 로그인 화면으로 복귀합니다.
struct RegisterView: View {
    // MARK: - Properties

    /// 앱 전역 상태(로그인/로그아웃/세션 등) 관리 객체
    @EnvironmentObject var appViewModel: AppViewModel
    /// Toast 이벤트를 화면에 표시하기 위한 매니저
    @EnvironmentObject var toastManager: ToastManager
    /// 회원가입 비즈니스 로직을 담당하는 ViewModel (DI 가능)
    @StateObject private var viewModel = RegisterViewModel(authService: AuthServiceImpl())

    @Environment(\.dismiss) var dismiss

    // MARK: - Body
    var body: some View {
        ZStack {
            VStack {
                RegisterHeader { dismiss() }
                RegisterForm(viewModel: viewModel)
                SocialLoginSection()
                BottomLoginSwitch { dismiss() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
        .overlay(alignment: toastManager.placement == .top ? .top : .bottom) {
            // ToastManager가 관리하는 이벤트를 구독하여 상/하단에 Toast 표시
            if let event = toastManager.event {
                ToastView(event: event)
                    // 위치에 따른 진입/퇴장 애니메이션 적용
                    .transition(.move(edge: toastManager.placement == .top ? .top : .bottom).combined(with: .opacity))
                    .padding()
            }
        }
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
