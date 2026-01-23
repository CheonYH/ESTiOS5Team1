//
//  R2Service.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/23/26.
//

import Foundation

enum R2Endpoint {
    case presign

    var path: String { "/r2/presign" }

    var url: URL {
        APIEnvironment.baseURL.appendingPathComponent(path)
    }
}

protocol R2Service: Sendable {
    func presign(filename: String, expiresIn: Int) async throws -> R2PresignResponse
}

final class R2ServiceManager: R2Service {

    private let tokenStore: TokenStore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(tokenStore: TokenStore = .shared) {
        self.tokenStore = tokenStore
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    func presign(filename: String, expiresIn: Int) async throws -> R2PresignResponse {
        var request = try authorizedRequest(url: R2Endpoint.presign.url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(R2PresignRequest(filename: filename, expiresIn: expiresIn))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<empty>"
            print("[R2Service] status=\(http.statusCode) body=\(body)")
            throw URLError(.badServerResponse)
        }

        return try decoder.decode(R2PresignResponse.self, from: data)
    }

    private func authorizedRequest(url: URL, method: String) throws -> URLRequest {
        guard let token = tokenStore.accessToken() else {
            throw URLError(.userAuthenticationRequired)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(String("Bearer \(token)"), forHTTPHeaderField: "Authorization")
        return request
    }
}
