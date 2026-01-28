//
//  NicknameCreateView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/26/26.
//

import SwiftUI

/// 소셜 로그인 후 닉네임을 추가로 입력받는 화면입니다.
struct NicknameCreateView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var toast: ToastManager
    @StateObject private var vm: SocialRegisterViewModel

    init(prefilledEmail: String?) {
        _vm = StateObject(wrappedValue: SocialRegisterViewModel(email: prefilledEmail))
    }

    var body: some View {

        ZStack {
            VStack(spacing: 20) {

                Text("사용하실 닉네임을 입력해 주세요")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)

                TextField("", text: $vm.nickname, prompt: Text("닉네임을 입력해주세요").foregroundStyle(.textPrimary.opacity(0.3)))
                    .font(.callout)
                    .padding(Spacing.pv10)
                    .foregroundStyle(.textPrimary)
                    .id(RegisterField.nickname)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 37/255, green: 37/255, blue: 57/255))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.gray.opacity(0.6), lineWidth: 1)
                    )

                Text("닉네임은 2~12자, 이모지/숫자만 불가, 동일 문자 3회 이상 반복 불가")
                    .font(.caption)
                    .foregroundStyle(.textPrimary.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("닉네임 생성") {
                    Task {
                        let event = await vm.submit(appViewModel: appVM)
                        toast.show(event)
                    }
                }
                .font(.title2)
                .bold()
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purplePrimary)
                )
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.BG)
    }
}

#Preview {
    NicknameCreateView(prefilledEmail: "test@example.com")
        .environmentObject(ToastManager())
}
