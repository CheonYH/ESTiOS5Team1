//
//  SocialRegisterView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/19/26.
//

import SwiftUI

struct SocialRegisterView: View {

    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var toast: ToastManager
    @StateObject private var vm: SocialRegisterViewModel

    init(prefilledEmail: String?) {
        _vm = StateObject(wrappedValue: SocialRegisterViewModel(email: prefilledEmail))
    }

    var body: some View {
        VStack(spacing: 20) {

            if let email = vm.email {
                Text("이메일: \(email)")
                    .font(.headline)
            }

            TextField("닉네임 입력", text: $vm.nickname)
                .textFieldStyle(.roundedBorder)

            Button("가입 완료") {
                Task {
                    let event = await vm.submit(appViewModel: appVM)
                    toast.show(event)
                }
            }
            .buttonStyle(.borderedProminent)

        }
        .padding()
    }
}
