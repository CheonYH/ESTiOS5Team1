//
//  FirebaseBootstrap.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/19/26.
//
import Foundation
import Firebase

/// 서버에서 내려온 Firebase 설정으로 SDK를 초기화합니다.
///
/// 앱 실행 시점에 동적으로 설정을 받아야 할 때 사용합니다.
final class FirebaseBootstrap {
    static let shared = FirebaseBootstrap()

    /// 설정 성공/실패를 completion으로 전달합니다.
    func configure(completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let options = try await fetchFromBackend()
                await MainActor.run {
                    // 이미 Firebase가 설정되어 있는지 체크 (중복 실행 방지)
                    if FirebaseApp.app() == nil {
                        FirebaseApp.configure(options: options)
                    }
                    print("✅ Firebase Configured Successfully")
                    completion(true)
                }
            } catch {
                print("❌ Firebase Configuration Failed: \(error)")
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }

    private func fetchFromBackend() async throws -> FirebaseOptions {
        let (data, _) = try await URLSession.shared.data(
            from: URL(string: "https://port-0-ios5team-mk6rdyqw52cca57c.sel3.cloudtype.app/firebase/config")!
        )

        let config = try JSONDecoder().decode(FirebaseConfig.self, from: data)

        // 중요: 생성 시점에 필요한 필수 값들을 확인하세요.
        let options = FirebaseOptions(
            googleAppID: config.appId,
            gcmSenderID: config.gcmSenderId
        )
        options.apiKey = config.apiKey
        options.projectID = config.projectId
        options.bundleID = Bundle.main.bundleIdentifier ?? "" // bundleID가 필요한 구성이라 함께 세팅합니다.
        options.storageBucket = config.storageBucket
        options.clientID = config.clientId

        return options
    }
}
