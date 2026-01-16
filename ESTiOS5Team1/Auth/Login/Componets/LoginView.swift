//
//  LoginView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import SwiftUI

struct LoginView: View {

    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = AuthViewModel(service: AuthServiceImpl())

    var body: some View {
        NavigationStack {
            ZStack {

                VStack {
                    LoginHeader()

                    LoginForm(viewModel: viewModel, appViewModel: appViewModel)

                    BottomRegisterSwitch()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.BG)
            }
        }

    }
}

    #Preview {
        LoginView()
    }
