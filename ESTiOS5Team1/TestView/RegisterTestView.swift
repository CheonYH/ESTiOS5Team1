//
//  RegisterTestView.swift
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

struct RegisterTestView: View {

    @StateObject private var viewModel = RegisterViewModel(authService: AuthServiceImpl())

    var body: some View {

        ZStack {
            VStack(spacing: 18) {

                TextField("이메일 입력", text: $viewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)

                SecureField("비밀번호 입력", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)

                TextField("닉네임 입력", text: $viewModel.nickname)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task {
                        await viewModel.register()
                    }
                } label: {
                    Text("회원가입")
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.blue))
                }

                if let result = viewModel.result {
                    Text(result)
                        .foregroundStyle(.green)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}

#Preview {
    RegisterTestView()
}
