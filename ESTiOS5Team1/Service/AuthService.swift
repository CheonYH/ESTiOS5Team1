//
//  AuthService.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import Foundation

protocol AuthService: Sendable {
    func login(email: String, password: String) async throws -> LoginResponse
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

        do {
            let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
            print("DECODE SUCCESS:", decoded)
            return decoded
        } catch {
            print("DECODE ERROR:", error)
            throw error
        }
    }
}

