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
        do {
            return try await r2Service.presign(filename: filename, expiresIn: expiresIn)
        }  catch {
            errorMessage = "프리사인 실패"
            return nil
        }
    }
}
