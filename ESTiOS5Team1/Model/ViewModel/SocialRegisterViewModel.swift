//
//  SocialRegisterViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/19/26.
//
import Foundation
import Combine

@MainActor
final class SocialRegisterViewModel: ObservableObject {

    @Published var email: String?
    @Published var nickname: String = ""
    private let service: AuthService = AuthServiceImpl()

    init(email: String?) {
        self.email = email
    }

    @discardableResult
    func submit(appViewModel: AppViewModel) async -> FeedbackEvent {

        print("[SocialRegister] submit START - nickname=\(nickname)")

        guard !nickname.isEmpty else {
            print("[SocialRegister] nickname empty")
            return FeedbackEvent(.auth, .warning, "닉네임을 입력해주세요.")
        }

        do {
            print("[SocialRegister] calling service.socialRegister")
            let token = try await service.socialRegister(
                provider: "google",
                providerUid: appViewModel.socialProviderUid ?? "",
                nickname: nickname,
                email: appViewModel.prefilledEmail
            )

            print("[SocialRegister] server returned token")
            TokenStore.shared.updateTokens(pair: token)

            appViewModel.state = .signedIn
            print("[SocialRegister] appVM.state = signedIn")

            return FeedbackEvent(.auth, .success, "가입 완료!")

        } catch {
            print("[SocialRegister] ERROR:", error)
            return FeedbackEvent(.auth, .error, "가입 실패")
        }
    }

}
