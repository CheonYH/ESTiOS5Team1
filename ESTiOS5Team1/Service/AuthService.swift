//
//  AuthService.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import Foundation

protocol AuthService: Sendable {
    func login(email: String, password: String) async throws -> LoginResponse

    @discardableResult
    func refresh() async throws -> TokenPair
}

final class AuthServiceImpl: AuthService {
    func login(email: String, password: String) async throws -> LoginResponse {
        let request = LoginRequest(email: email, password: password)

        guard let url = URL(string: "https://port-0-ios5team-mk6rdyqw52cca57c.sel3.cloudtype.app/auth/login") else {
            fatalError("Wrong url")
        }

        var urlrequest = URLRequest(url: url)
        urlrequest.httpMethod = "POST"
        urlrequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = try JSONEncoder().encode(request)
        urlrequest.httpBody = body

        print("REQUEST JSON:", String(data: body, encoding: .utf8) ?? "nil")

        let (data, response) = try await URLSession.shared.data(for: urlrequest)

        if let http = response as? HTTPURLResponse {
            print("RESPONSE STATUS:", http.statusCode)
            print("RESPONSE HEADERS:", http.allHeaderFields)
        }

        print("RESPONSE RAW:", String(data: data, encoding: .utf8) ?? "nil")

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
        print("DECODE SUCCESS:", decoded)

        // 여기서 토큰 저장
        TokenStore.shared.updateTokens(response: decoded)

        return decoded
    }

    @discardableResult
    func refresh() async throws -> TokenPair {
        guard let refreshToken = TokenStore.shared.refreshToken() else {
            throw URLError(.userAuthenticationRequired)
        }

        let requestBody = RefreshRequest(refreshToken: refreshToken)

        guard let url = URL(string: "https://port-0-ios5team-mk6rdyqw52cca57c.sel3.cloudtype.app/auth/refresh") else {
            fatalError("Wrong url")
        }

        var urlrequest = URLRequest(url: url)
        urlrequest.httpMethod = "POST"
        urlrequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = try JSONEncoder().encode(requestBody)
        urlrequest.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: urlrequest)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(TokenPair.self, from: data)

        // 새 토큰으로 갱신 (rotation)
        TokenStore.shared.updateTokens(response: decoded)

        return decoded
    }
}

