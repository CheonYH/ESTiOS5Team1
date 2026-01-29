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

    /// 소셜 로그인 이메일입니다. (없을 수 있음)
    @Published var email: String?
    /// 닉네임 입력값입니다.
    @Published var nickname: String = ""
    /// 인증 서비스입니다.
    private let service: AuthService = AuthServiceImpl()

    /// 초기 이메일 값을 주입받습니다.
    init(email: String?) {
        self.email = email
    }

    /// 소셜 가입 요청을 수행하고 결과 이벤트를 반환합니다.
    @discardableResult
    func submit(appViewModel: AppViewModel) async -> FeedbackEvent {

        print("[SocialRegister] submit START - nickname=\(nickname)")

        // 1) 로컬 닉네임 검증
        if let validationError = nicknameValidationError() {
            print("[SocialRegister] nickname invalid")
            return validationError
        }

        // 2) 소셜 로그인에서 받은 providerUid가 있어야 가입 가능
        guard let providerUid = appViewModel.socialProviderUid, !providerUid.isEmpty else {
            print("[SocialRegister] providerUid missing")
            return FeedbackEvent(.auth, .error, "소셜 인증 정보가 없습니다. 다시 로그인해주세요.")
        }

        do {
            let start = CFAbsoluteTimeGetCurrent()
            print("[SocialRegister] submit START timing")

            // 3) 닉네임 중복 검사
            print("[SocialRegister] checking nickname")
            let isAvailable = try await service.checkNickname(nickname)
            let afterNickname = CFAbsoluteTimeGetCurrent()
            print("[SocialRegister] nickname check done in \(String(format: "%.3f", afterNickname - start))s")
            if !isAvailable {
                print("[SocialRegister] nickname duplicate")
                return FeedbackEvent(.auth, .warning, "이미 사용 중인 닉네임입니다.")
            }
            print("[SocialRegister] nickname available")

            // 4) 소셜 가입 요청
            print("[SocialRegister] calling service.socialRegister")
            let token = try await service.socialRegister(
                provider: "google",
                providerUid: providerUid,
                nickname: nickname,
                email: appViewModel.prefilledEmail
            )
            let afterRegister = CFAbsoluteTimeGetCurrent()
            print("[SocialRegister] register network done in \(String(format: "%.3f", afterRegister - afterNickname))s total \(String(format: "%.3f", afterRegister - start))s")

            print("[SocialRegister] server returned token")
            TokenStore.shared.updateTokens(pair: token)

            appViewModel.state = .signedIn
            let afterState = CFAbsoluteTimeGetCurrent()
            print("[SocialRegister] state updated in \(String(format: "%.3f", afterState - afterRegister))s total \(String(format: "%.3f", afterState - start))s")
            print("[SocialRegister] appVM.state = signedIn")

            return FeedbackEvent(.auth, .success, "가입 완료!")

        } catch {
            print("[SocialRegister] ERROR:", error)
            return FeedbackEvent(.auth, .error, "가입 실패")
        }
    }

    // MARK: - Validation Helpers
    /// 닉네임 검증 결과를 메시지로 반환합니다.
    private func nicknameValidationError() -> FeedbackEvent? {
        switch NicknameValidator.validate(nickname) {
            case .valid:
                return nil
            case .empty:
                print("[SocialRegister] nickname empty")
                return FeedbackEvent(.auth, .warning, "닉네임을 입력해주세요.")
            case .length:
                return FeedbackEvent(.auth, .warning, "닉네임은 2~12자로 입력해주세요.")
            case .emoji:
                return FeedbackEvent(.auth, .warning, "닉네임에는 이모지를 사용할 수 없습니다.")
            case .repeating:
                return FeedbackEvent(.auth, .warning, "동일 문자는 3회 이상 반복할 수 없습니다.")
            case .numericOnly:
                return FeedbackEvent(.auth, .warning, "닉네임은 숫자만 사용할 수 없습니다.")
        }
    }

}
