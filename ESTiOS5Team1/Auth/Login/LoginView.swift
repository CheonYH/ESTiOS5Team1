//
//  LoginView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import SwiftUI

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
    @FocusState private var focusedField: LoginField?

    // MARK: - Body
    var body: some View {
        NavigationStack {

            ZStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack {
                            LoginHeader()

                            LoginForm(viewModel: viewModel, focusedField: $focusedField)

                            BottomRegisterSwitch()
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: focusedField) { _, field in
                        guard let field else { return }
                        withAnimation(.easeOut(duration: 0.2)) {
                            // 포커스된 입력칸이 키보드에 가려지지 않도록 스크롤합니다.
                            proxy.scrollTo(field, anchor: .bottom)
                        }
                    }
                }

            }
            .background(Color.BG)
            .toolbar(.hidden, for: .navigationBar)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        Text("로그인 중...")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black.opacity(0.6))
                    )
                    .transition(.opacity)
                }
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

    NavigationStack {
        LoginView()
    }
    .environmentObject(appVM)
    .environmentObject(toast)
}
