//
//  LoginView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import SwiftUI
import Combine

/// 로그인 화면입니다.
///
/// - Composition:
///     `LoginHeader`, `LoginForm`, `BottomRegisterSwitch`로 구성됩니다.
/// - State Management:
///     `ToastManager`의 이벤트를 overlay로 구독하여 로그인 결과를 Toast로 표시합니다.
/// - Behavior:
///     `onAppear`에서 `AppViewModel.prefilledEmail`이 있으면 입력 필드에 채워 넣습니다.
struct LoginView: View {
    // MARK: - Properties
    
    /// 앱 전역 상태(세션/화면 흐름)를 관리하는 ViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    /// 로그인/로그아웃 관련 Toast 이벤트를 표시하는 매니저
    @EnvironmentObject var toastManager: ToastManager

    /// 로그인 로직과 입력 상태를 담당하는 ViewModel (DI 가능)
    @StateObject private var viewModel = AuthViewModel(service: AuthServiceImpl())


    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {

                VStack {
                    LoginHeader()

                    LoginForm(viewModel: viewModel)

                    BottomRegisterSwitch()

                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.BG)

            }
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
        .onAppear {
            // 회원가입 직후 전달된 이메일이 있으면 자동 입력
            if let email = appViewModel.prefilledEmail {
                viewModel.email = email
                appViewModel.prefilledEmail = nil
            }
        }
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

