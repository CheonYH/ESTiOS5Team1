//
//  LoginForm.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

enum LoginField: Hashable {
    case email
    case password
}

/// 로그인 폼 View입니다.
///
/// - Purpose:
///     이메일/비밀번호 입력과 로그인 액션을 제공합니다.
/// - Dependencies:
///     `AuthViewModel`로 입력을 바인딩하고, `AppViewModel` 및 `ToastManager`와 상호작용합니다.
/// - Important:
///     실제 로그인 로직은 ViewModel에서 수행되며, 이 View는 UI와 이벤트 트리거만 담당합니다.
/// - Endpoint:
///     `POST /auth/login`
///     `POST /auth/social` (Google)
///     `GET /auth/me` (로그인 성공 후 상태 동기화)
struct LoginForm: View {
    // MARK: - Properties

    /// 사용자 입력 바인딩 및 `login()` 호출을 담당하는 ViewModel
    @ObservedObject var viewModel: AuthViewModel
    /// 전역 앱 상태(App 상태 전환 등)에 접근합니다.
    @EnvironmentObject var appViewModel: AppViewModel
    /// 로그인 결과를 Toast로 표시하기 위한 매니저
    @EnvironmentObject var toast: ToastManager

    var focusedField: FocusState<LoginField?>.Binding

    // MARK: - Body
    var body: some View {

        VStack(alignment: .leading, spacing: 15) {

            Text("Email")
                .font(.headline)
                .foregroundStyle(.white)

            TextField("", text: $viewModel.email, prompt: Text("이메일을 입력해 주세요").foregroundStyle(.textPrimary.opacity(0.4)))
                .font(.callout)
                .padding(Spacing.pv10)
                .foregroundStyle(.textPrimary)
                .focused(focusedField, equals: .email)
                .textInputAutocapitalization(.never)
                .id(LoginField.email)
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
                .foregroundStyle(.white)

            SecureField("", text: $viewModel.password, prompt: Text("비밀번호를 입력해 주세요").foregroundStyle(.textPrimary.opacity(0.4)))
                .font(.callout)
                .padding(Spacing.pv10)
                .foregroundStyle(.textPrimary)
                .focused(focusedField, equals: .password)
                .textInputAutocapitalization(.never)
                .id(LoginField.password)
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
                    // ViewModel을 통해 로그인 요청 → UI로 전달할 FeedbackEvent 반환
                    let feedback = await viewModel.login(appViewModel: appViewModel)
                    // 반환된 이벤트를 ToastManager에 전달하여 화면에 표시
                    toast.show(feedback)
                }
            } label: {
                Text("로그인")
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

        }
        .padding(Spacing.pv10)

        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.gray.opacity(0.4))
                .layoutPriority(0)

            Text("다른 방법으로 로그인")
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

        HStack(spacing: 16) {

            Button {
                Task {
                    await viewModel.signInWithGoogle(appViewModel: appViewModel)
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

            /* Button {

            } label: {
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
            }

            Button {

            } label: {
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
            }

             */

        }
        .padding(Spacing.pv10)
    }
}

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
