//
//  RegisterForm.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

enum RegisterField: Hashable {
    case email
    case password
    case confirmPassword
    case nickname
}

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
    var focusedField: FocusState<RegisterField?>.Binding
    /// 전역 앱 상태(App 상태 전환, prefilledEmail 설정 등)에 접근합니다.
    @EnvironmentObject var appViewModel: AppViewModel
    /// 회원가입 결과를 Toast로 표시하기 위한 매니저
    @EnvironmentObject var toastManager: ToastManager
    @StateObject private var authViewModel = AuthViewModel(service: AuthServiceImpl())
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {

            Text("Email")
                .font(.headline)
                .foregroundStyle(.textPrimary)

            TextField("", text: $viewModel.email, prompt: Text("이메일를 입력해 주세요").foregroundStyle(.textPrimary.opacity(0.4)))
                .font(.callout)
                .autocapitalization(.none)
                .foregroundStyle(.textPrimary)
                .padding(Spacing.pv10)
                .focused(focusedField, equals: .email)
                .id(RegisterField.email)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 37/255, green: 37/255, blue: 57/255))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.gray.opacity(0.6), lineWidth: 1)
                )

            Text("Password")
                .font(.headline)
                .foregroundStyle(.textPrimary)

            SecureField("", text: $viewModel.password, prompt: Text("비밀번호를 입력해 주세요").foregroundStyle(.textPrimary.opacity(0.4)))
                .font(.callout)
                .padding(Spacing.pv10)
                .foregroundStyle(.textPrimary)
                .textContentType(.newPassword)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused(focusedField, equals: .password)
                .id(RegisterField.password)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 37/255, green: 37/255, blue: 57/255))
                )
                . overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.gray.opacity(0.6), lineWidth: 1)
                )

            Text("Confirm Password")
                .font(.headline)
                .foregroundStyle(.textPrimary)

            SecureField("", text: $viewModel.confirmPassword, prompt: Text("비밀번호를 다시 입력해 주세요").foregroundStyle(.textPrimary.opacity(0.4)))
                .font(.callout)
                .padding(Spacing.pv10)
                .textContentType(.newPassword)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .foregroundStyle(.textPrimary)
                .focused(focusedField, equals: .confirmPassword)
                .id(RegisterField.confirmPassword)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 37/255, green: 37/255, blue: 57/255))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.gray.opacity(0.6), lineWidth: 1)
                )

            Text("NickName")
                .font(.headline)
                .foregroundStyle(.textPrimary)

            TextField("", text: $viewModel.nickname, prompt: Text("닉네임을 입력해 주세요").foregroundStyle(.textPrimary.opacity(0.4)))
                .font(.callout)
                .padding(Spacing.pv10)
                .foregroundStyle(.textPrimary)
                .focused(focusedField, equals: .nickname)
                .id(RegisterField.nickname)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 37/255, green: 37/255, blue: 57/255))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.gray.opacity(0.6), lineWidth: 1)
                )

            Text("닉네임은 2~12자, 이모지/숫자만 불가, 동일 문자 3회 이상 반복 불가")
                .font(.caption)
                .foregroundStyle(.textPrimary.opacity(0.7))

            Button {
                Task {
                    // ViewModel을 통해 회원가입 요청 → UI로 전달할 FeedbackEvent 반환
                    let event = await viewModel.register(appViewModel: appViewModel)
                    // 반환된 이벤트를 ToastManager에 전달하여 화면에 표시
                    toastManager.show(event)

                    if event.status == .success {
                        dismiss()  // 로그인 화면으로 pop
                    }
                }
            } label: {
                Text("가입하기")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.purplePrimary)
                    )
            }
            .padding(.top, Spacing.pv10)
            .padding(.bottom, Spacing.pv10)

            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.gray.opacity(0.4))
                    .layoutPriority(0)

                Text("다른 방법으로 가입")
                    .font(.headline)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(.gray.opacity(0.7))
                    .layoutPriority(1)

                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.gray.opacity(0.4))
                    .layoutPriority(0)
            }
            .padding(Spacing.pv10)

            HStack(alignment: .center, spacing: 16) {

                Button {
                    Task {
                        let event = await authViewModel.signInWithGoogle(appViewModel: appViewModel)
                        toastManager.show(event)
                    }
                } label: {
                    Image("google")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                }

               /* Button { } label: {
                    Image(systemName: "playstation.logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .padding(12)
                        .frame(width: 120, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundStyle(.white)
                } */

               /* Button { } label: {
                    Image(systemName: "xbox.logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .padding(12)
                        .frame(width: 120, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundStyle(.white)
                } */

            }
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
