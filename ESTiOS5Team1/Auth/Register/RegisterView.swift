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

struct RegisterView: View {

    @StateObject private var viewModel = RegisterViewModel(authService: AuthServiceImpl())
    @Environment(\.dismiss) var dismiss
    var body: some View {

        ZStack {

            VStack {
                RegisterHeader { dismiss() }

                RegisterForm(viewModel: viewModel)

                SocialLoginSection()

                BottomLoginSwitch { dismiss() }

            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)

    }
}

#Preview {
    RegisterView()
}
