//
//  RegisterForm.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

struct RegisterForm: View {
    @ObservedObject var viewModel: RegisterViewModel
    
    var body: some View {
        VStack(alignment: .leading , spacing: 15) {

            Text("Email")
                .font(Font.title3.bold())
                .foregroundStyle(.textPrimary)

            TextField("", text: $viewModel.email, prompt: Text("이메일를 입력해 주세요").foregroundStyle(.white.opacity(0.3)))
                .autocapitalization(.none)
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
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 37/255, green: 37/255, blue: 57/255))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.gray.opacity(0.6), lineWidth: 1)
                )


            Text("Confirm Password")
                .font(Font.title3.bold())
                .foregroundStyle(.textPrimary)

            SecureField("", text: $viewModel.confirmPassword, prompt: Text("비밀번호를 다시 입력해 주세요").foregroundStyle(.white.opacity(0.3)))
                .padding(Spacing.pv10)
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
                    await viewModel.register()
                }
            } label: {
                Text("Sign Up")
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
    RegisterView()
}
