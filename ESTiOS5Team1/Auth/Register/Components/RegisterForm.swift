//
//  RegisterForm.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

/// 회원가입 폼 View입니다.
///
/// - Purpose:
///     이메일/비밀번호/닉네임 입력과 회원가입 액션을 제공합니다.
/// - Dependencies:
///     `RegisterViewModel`로 입력을 바인딩하고, `AppViewModel` 및 `ToastManager`와 상호작용합니다.
/// - Important:
///     실제 회원가입 로직은 ViewModel에서 수행되며, 이 View는 UI와 이벤트 트리거만 담당합니다.
struct RegisterForm: View {
    // MARK: - Properties

    /// 사용자 입력 바인딩 및 `register()` 호출을 담당하는 ViewModel
    @ObservedObject var viewModel: RegisterViewModel
    /// 전역 앱 상태(App 상태 전환, prefilledEmail 설정 등)에 접근합니다.
    @EnvironmentObject var appViewModel: AppViewModel
    /// 회원가입 결과를 Toast로 표시하기 위한 매니저
    @EnvironmentObject var toastManager: ToastManager

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {

            Text("Email")
                .font(Font.title3.bold())
                .foregroundStyle(.textPrimary)

            TextField("", text: $viewModel.email, prompt: Text("이메일를 입력해 주세요").foregroundStyle(.white.opacity(0.3)))
                .autocapitalization(.none)
                .foregroundStyle(.textPrimary)
                .padding(Spacing.pv10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 37/255, green: 37/255, blue: 57/255))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.gray.opacity(0.6), lineWidth: 1)
                )

            Text("Password")
                .font(Font.title3.bold())
                .foregroundStyle(.textPrimary)

            SecureField("", text: $viewModel.password, prompt: Text("비밀번호를 입력해 주세요").foregroundStyle(.white.opacity(0.3)))
                .padding(Spacing.pv10)
                .foregroundStyle(.textPrimary)
                .textContentType(.newPassword)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 37/255, green: 37/255, blue: 57/255))
                )
                . overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.gray.opacity(0.6), lineWidth: 1)
                )

            Text("Confirm Password")
                .font(Font.title3.bold())
                .foregroundStyle(.textPrimary)

            SecureField("", text: $viewModel.confirmPassword, prompt: Text("비밀번호를 다시 입력해 주세요").foregroundStyle(.white.opacity(0.3)))
                .padding(Spacing.pv10)
                .textContentType(.newPassword)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .foregroundStyle(.textPrimary)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 37/255, green: 37/255, blue: 57/255))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.gray.opacity(0.6), lineWidth: 1)
                )

            Text("NickName")
                .font(Font.title3.bold())
                .foregroundStyle(.textPrimary)

            TextField("", text: $viewModel.nickname, prompt: Text("닉네임을 입력해 주세요").foregroundStyle(.white.opacity(0.3)))
                .padding(Spacing.pv10)
                .foregroundStyle(.textPrimary)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 37/255, green: 37/255, blue: 57/255))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.gray.opacity(0.6), lineWidth: 1)
                )

            Button {
                Task {
                    // ViewModel을 통해 회원가입 요청 → UI로 전달할 FeedbackEvent 반환
                    let event = await viewModel.register(appViewModel: appViewModel)
                    // 반환된 이벤트를 ToastManager에 전달하여 화면에 표시
                    toastManager.show(event)
                }
            } label: {
                Text("가입하기")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.purplePrimary)
                    )
            }
            .padding(.top, Spacing.pv10)
            .padding(.bottom, Spacing.pv10)
        }
        .padding(Spacing.pv10)
    }
}

#Preview {
    let toast = ToastManager()
    let auth = AuthServiceImpl()
    let appVM = AppViewModel(authService: auth, toast: toast)

    RegisterView()
        .environmentObject(appVM)
        .environmentObject(toast)
}
