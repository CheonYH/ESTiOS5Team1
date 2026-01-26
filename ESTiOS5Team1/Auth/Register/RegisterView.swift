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
    @FocusState private var focusedField: RegisterField?

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack {
                        RegisterHeader()
                        RegisterForm(viewModel: viewModel, focusedField: $focusedField)
                        BottomLoginSwitch { dismiss() }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: focusedField) { field in
                    guard let field else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        // 포커스된 입력칸이 키보드에 가려지지 않도록 스크롤합니다.
                        proxy.scrollTo(field, anchor: .bottom)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        Text("회원가입 중...")
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
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("계정 생성")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.visible, for: .navigationBar)
    }
}

// MARK: - Preview
#Preview {
    let toast = ToastManager()
    let auth = AuthServiceImpl()
    let appVM = AppViewModel(authService: auth, toast: toast)

    NavigationStack {
        RegisterView()
    }
    .environmentObject(appVM)
    .environmentObject(toast)
}
