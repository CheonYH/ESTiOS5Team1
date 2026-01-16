//
//  LoginForm.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

struct LoginForm: View {
    
    @ObservedObject var viewModel: AuthViewModel
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {

        VStack(alignment: .leading, spacing: 15) {
            
            Text("Email")
                .font(Font.title3.bold())
                .foregroundStyle(.white)
            
            TextField("", text: $viewModel.email, prompt: Text("이메일을 입력해 주세요").foregroundStyle(.white.opacity(0.3)))
                .padding(10)
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
                .foregroundStyle(.white)
            
            SecureField("", text: $viewModel.password, prompt: Text("비밀번호를 입력해 주세요").foregroundStyle(.white.opacity(0.3)))
                .padding(10)
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
                    await viewModel.login(appViewModel: appViewModel)
                }
            } label: {
                Text("Login")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.purplePrimary)
                    )
            }
            .padding(.top, 10)
            
        }
        .padding(10)
        
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.gray.opacity(0.4))
                .layoutPriority(0)
            
            Text("Or continue with")
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
        .padding(10)
        
        HStack(spacing: 16) {
            Button {
                
            } label: {
                Image(systemName: "applelogo")
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
            
        }

    }
}

#Preview {
    LoginView()
        .environmentObject(AppViewModel(authService: AuthServiceImpl()))
}
