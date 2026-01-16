//
//  LoginHeader.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

struct LoginHeader: View {
    var body: some View {
        VStack(spacing: 10) {

            Image(systemName: "gamecontroller.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.purplePrimary)
                .frame(width: 44, height: 44)

            Text("GameValut")
                .font(.system(size: 48))
                .bold()
                .foregroundStyle(.white)
            Text("Your gaming universe awaits")
                .font(.title3)
                .bold()
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)

        VStack(alignment: .leading, spacing: 10) {
            Text("Welcome Back")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(.white)

            Text("Login to continue your adventure")
                .font(.title3)
                .bold()
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .padding(10)
    }
}

#Preview {
    LoginHeader()
}
