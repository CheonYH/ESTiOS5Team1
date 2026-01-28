//
//  ProfileViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/23/26.
//

import Foundation
import Combine

/// 프로필 조회/생성/업데이트 및 업로드 흐름을 담당하는 ViewModel입니다.
@MainActor
final class ProfileViewModel: ObservableObject {

    /// 입력 중인 닉네임입니다.
    @Published var nickname: String = ""
    /// 입력 중인 프로필 이미지 URL 문자열입니다.
    @Published var avatarUrl: String = ""
    /// 현재 프로필 응답 데이터입니다.
    @Published var profile: ProfileResponse?
    /// 로딩 상태 표시용 플래그입니다.
    @Published var isLoading: Bool = false
    /// 사용자에게 표시할 에러 메시지입니다.
    @Published var errorMessage: String = ""

    /// 프로필 API 서비스입니다.
    private let profileService: ProfileService
    /// R2 업로드 프리사인/업로드 서비스입니다.
    private let r2Service: R2Service

    /// 의존성 주입을 지원하는 초기화 메서드입니다.
    init(profileService: ProfileService? = nil, r2Service: R2Service? = nil) {
        self.profileService = profileService ?? ProfileServiceManager()
        self.r2Service = r2Service ?? R2ServiceManager()
    }

    /// 프로필을 조회합니다.
    func fetchProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await profileService.fetch()
            profile = result
            nickname = result.nickname
            avatarUrl = result.avatarUrl
        } catch {
            errorMessage = "프로필 불러오기 실패"
        }
    }

    /// 프로필을 생성합니다.
    func createProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await profileService.create(nickname: nickname, avatarUrl: avatarUrl)
            profile = result
        } catch {
            errorMessage = "프로필 생성 실패"
        }
    }

    /// 프로필을 업데이트합니다.
    func updateProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await profileService.update(nickname: nickname, avatarUrl: avatarUrl)
            profile = result
        } catch {
            errorMessage = "프로필 업데이트 실패"
        }
    }

    /// R2 업로드용 프리사인 URL을 요청합니다.
    func presign(filename: String, expiresIn: Int = 900) async -> R2PresignResponse? {
        print("[Presign] start filename=\(filename) expiresIn=\(expiresIn)")
        do {
            let result = try await r2Service.presign(filename: filename, expiresIn: expiresIn)
            print("[Presign] success key=\(result.key)")
            return result
        } catch {
            print("[Presign] failed error=\(error)")
            errorMessage = "프리사인 실패"
            return nil
        }
    }

    /// 프리사인 URL로 파일을 업로드합니다.
    func uploadToPresignedUrl(_ uploadUrl: String, data: Data, contentType: String = "image/png") async -> Bool {
        guard let url = URL(string: uploadUrl) else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return false
            }
            return (200...299).contains(http.statusCode)
        } catch {
            print("[Upload] failed error=\(error)")
            return false
        }
    }
}
