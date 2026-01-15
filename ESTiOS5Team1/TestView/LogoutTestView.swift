//
//  LogoutTestView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import SwiftUI

struct LogoutTestView: View {

    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var authViewModel = AuthViewModel(service: AuthServiceImpl())

    var body: some View {

        Button {
            
            authViewModel.logout(appViewModel: appViewModel)

        } label: {
            Text("Log Out")
                .foregroundStyle(.black)
                .padding(10)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.yellow)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.gray.opacity(0.6), lineWidth: 1)
        )

    }
}

#Preview {
    LogoutTestView()
}
