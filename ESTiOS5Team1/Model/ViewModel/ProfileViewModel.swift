//
//  ProfileViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/23/26.
//

import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var nickname: String = ""
    @Published var avatarUrl: String = ""
    @Published var profile: ProfileResponse?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""

    private let profileService: ProfileService
    private let r2Service: R2Service

    init(profileService: ProfileService? = nil, r2Service: R2Service? = nil) {
        self.profileService = profileService ?? ProfileServiceManager()
        self.r2Service = r2Service ?? R2ServiceManager()
    }

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
