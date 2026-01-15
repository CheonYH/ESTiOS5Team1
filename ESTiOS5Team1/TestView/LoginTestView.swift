//
//  LoginTestView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import SwiftUI

struct LoginTestView: View {

    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = AuthViewModel(service: AuthServiceImpl())

    var body: some View {
        NavigationStack() {
            ZStack {

                VStack(spacing: 20) {

                    TextField("이메일를 입력해 주세요", text: $viewModel.email)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.gray.opacity(0.6), lineWidth: 1)
                        )

                    SecureField("비밀번호를 입력해 주세요", text: $viewModel.password)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.gray.opacity(0.6), lineWidth: 1)
                        )

                    Button {
                        Task {
                            await viewModel.login(appViewModel: appViewModel)
                        }
                    } label: {
                        Text("Login")
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.purple)
                            )
                    }
                    .padding(.top, 10)


                    NavigationLink(destination: RegisterTestView()) {
                        Text("Register")
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.purple)
                            )
                    }
                }
                .font(.title)
                .padding(10)

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        }

    }
}

#Preview {
    LoginTestView()
}
