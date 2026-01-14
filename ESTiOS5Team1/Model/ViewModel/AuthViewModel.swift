//
//  AuthViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var result: String = ""
    @Published var isLoading: Bool = false

    private let service: AuthService

    init(service: AuthService) {
        self.service = service
    }

    func login() {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let response = try await service.login(email: self.email, password: self.password)
                result = "로그인 성공: \(response.accessToken)"
            } catch {
                result = "로그인 실패: \(error)"
            }
        }
    }
}
