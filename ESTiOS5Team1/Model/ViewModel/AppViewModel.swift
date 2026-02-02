//
//  AppViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import Foundation
import Combine
import Firebase
import FirebaseCrashlytics
import GoogleSignIn
import Kingfisher

/// 앱 전역 상태(세션/라우팅)를 관리하는 ViewModel입니다.
@MainActor
final class AppViewModel: ObservableObject {

    /// 앱 전역 인증/라우팅 상태입니다.
    enum State {
        case launching            // 앱 처음 켜짐
        case signedOut            // 로그인 필요
        case signedIn             // 로그인 완료
        case socialNeedsRegister
    }

    /// 현재 앱 상태입니다.
    @Published var state: State = .launching
    /// 초기화 완료 여부입니다. (스플래시 제어용)
    @Published var isInitialized: Bool = false
    /// 소셜 로그인 후 입력 화면에 미리 채우는 이메일입니다.
    @Published var prefilledEmail: String?
    /// 소셜 로그인 제공자 UID입니다.
    @Published var socialProviderUid: String?
    /// 서버 기준 온보딩 완료 여부입니다.
    @Published var onboardingCompleted: Bool = false

    /// Firebase 설정 완료 여부입니다.
    @Published var firebaseConfigured = false

    /// 인증 서비스입니다.
    private let authService: AuthService
    /// 토스트 메시지 관리자입니다.
    private let toast: ToastManager    // 주입 가능하게 할 수도 있음

    /// 의존성을 주입해 초기화합니다.
    init(authService: AuthService, toast: ToastManager) {
        self.authService = authService
        self.toast = toast
        Task {
            await initializeApp()
        }

        configureImageCache()
    }

    /// Firebase 설정과 세션 복구를 순서대로 수행합니다.
    private func initializeApp() async {
        do {
            // 1. Firebase 설정 완료 대기
            try await setupFirebase()

            // 2. Firebase가 준비된 후 세션 확인
            await restoreSession()
            isInitialized = true
        } catch {
            print("Initialization Error: \(error)")
            Crashlytics.crashlytics().record(error: error)
            Crashlytics.crashlytics().log("App 초기화 실패")
            // 설정 실패 시 앱 진입을 막거나 에러 메시지 출력
            state = .signedOut
            toast.show(FeedbackEvent(.auth, .error, "서버 설정 로드 실패"))
            isInitialized = true
        }
    }

    /// 이전 세션을 복구합니다 (자동 로그인)
    ///
    /// - Flow:
    ///     1. refreshToken 존재 여부 확인
    ///     2. refresh() 호출하여 accessToken 재발급 시도
    ///     3. 성공 → signedIn
    ///     4. 실패 → signedOut + 안내 메시지 출력
    ///
    /// - Important:
    ///     refreshToken이 만료될 수 있으므로 실패 시 사용자 안내 필요
    func restoreSession() async {
        guard TokenStore.shared.refreshToken() != nil else {
            state = .signedOut
            return
        }

        do {
            _ = try await authService.refresh()
            let me = try await authService.fetchMe()
            self.onboardingCompleted = me.onboardingCompleted ?? false
            state = .signedIn

        } catch let authError as AuthError {
            state = .signedOut
            switch authError {
                case .invalidCredentials:
                    toast.show(FeedbackEvent(.auth, .info, "세션이 만료되었습니다. 다시 로그인해주세요."))
                default:
                    toast.show(FeedbackEvent(.auth, .warning, "자동 로그인 실패. 다시 로그인해주세요."))
            }

        } catch {
            state = .signedOut
            Crashlytics.crashlytics().record(error: error)
            Crashlytics.crashlytics().log("세션 복구 실패")
            toast.show(FeedbackEvent(.auth, .error, "알 수 없는 오류가 발생했습니다."))
        }
    }

    /// 서버에서 Firebase 설정을 받아 초기화합니다.
    func setupFirebase() async throws {

        guard let url = URL(string: "https://port-0-ios5team-mk6rdyqw52cca57c.sel3.cloudtype.app/firebase/config") else { return }

        let (data, _) = try await URLSession.shared.data(from: url)
        let config = try JSONDecoder().decode(FirebaseConfig.self, from: data)

        let options = FirebaseOptions(
            googleAppID: config.appId,
            gcmSenderID: config.gcmSenderId
        )
        options.apiKey = config.apiKey
        options.projectID = config.projectId
        options.storageBucket = config.storageBucket
        options.clientID = config.clientId

        FirebaseApp.configure(options: options)

        await MainActor.run {
            self.firebaseConfigured = true
            print("Firebase 설정 완료!")
        }
    }

    /// 이미지 캐시 용량과 보존 기간을 설정합니다.
    private func configureImageCache() {
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 200 * 1024 * 1024  // 200MB
        cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024         // 500MB
        cache.diskStorage.config.expiration = .days(30)                // 30일 유지
    }
}
