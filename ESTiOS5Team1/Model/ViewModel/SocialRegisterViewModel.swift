//
//  SocialRegisterViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/19/26.
//
import Foundation
import Combine

/// 소셜 가입(닉네임 등록) 화면 상태를 관리하는 ViewModel입니다.
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

        guard let providerUid = appViewModel.socialProviderUid, !providerUid.isEmpty else {
            print("[SocialRegister] providerUid missing")
            return FeedbackEvent(.auth, .error, "소셜 인증 정보가 없습니다. 다시 로그인해주세요.")
        }

        do {

            print("[SocialRegister] checking nickname")
            let isAvailable = try await service.checkNickname(nickname)
            if !isAvailable {
                print("[SocialRegister] nickname duplicate")
                return FeedbackEvent(.auth, .warning, "이미 사용 중인 닉네임입니다.")
            }
            print("[SocialRegister] nickname available")

            print("[SocialRegister] calling service.socialRegister")
            let token = try await service.socialRegister(
                provider: "google",
                providerUid: providerUid,
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
