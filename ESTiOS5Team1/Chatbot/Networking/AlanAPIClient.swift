//
//  AlanAPIClient.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation

struct AlanAPIClient {
    struct Configuration: Sendable {
        let baseUrl: URL
        init(baseUrl: URL) {
            self.baseUrl = baseUrl
        }
    }

    enum AlanAPIError: LocalizedError {
        case invalidUrl
        case badStatus(Int, String)
        case emptyResponse
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .invalidUrl:
                return "Invalid Alan API URL."
            case .badStatus(let code, let body):
                return "Alan API failed. status=\(code), body=\(body)"
            case .emptyResponse:
                return "Alan API returned empty response."
            case .decodingFailed:
                return "Failed to decode Alan API response."
            }
        }
    }

    private let configuration: Configuration
    private let urlSession: URLSession

    // GET만 가능한 환경에서는 URL 길이 제한이 문제가 될 수 있다.
    // 실 환경에서 문제가 생기면 이 값을 줄이거나, 서버가 POST를 지원하도록 개선하는 게 정석이다.
    private let maxContentCharactersForGET: Int = 1200

    init(configuration: Configuration, urlSession: URLSession = .shared) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    func ask(content: String, clientId: String) async throws -> String {
        let safeContent = sanitizeForQuery(content, maxCharacters: maxContentCharactersForGET)

        var components = URLComponents(url: configuration.baseUrl, resolvingAgainstBaseURL: false)
        components?.path = "/api/v1/question"
        components?.queryItems = [
            URLQueryItem(name: "content", value: safeContent),
            URLQueryItem(name: "client_id", value: clientId)
        ]

        guard let url = components?.url else { throw AlanAPIError.invalidUrl }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(for: request)
        return try parseAlanResponse(data: data, response: response)
    }

    // 스웨거 기준: DELETE /api/v1/reset-state
    // Request body: { "client_id": "string" }
    func resetState(clientId: String) async throws -> String {
        guard let url = URL(string: "/api/v1/reset-state", relativeTo: configuration.baseUrl) else {
            throw AlanAPIError.invalidUrl
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["client_id": clientId])

        let (data, response) = try await urlSession.data(for: request)
        return try parseAlanResponse(data: data, response: response)
    }

    private func parseAlanResponse(data: Data, response: URLResponse) throws -> String {
        if let http = response as? HTTPURLResponse {
            if (200..<300).contains(http.statusCode) == false {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw AlanAPIError.badStatus(http.statusCode, body)
            }
        }

        // 서버 응답 형태가 일정하지 않을 수 있어 여러 후보를 순서대로 시도한다.
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let answer = obj["answer"] as? String { return try nonEmpty(answer) }
            if let speak = obj["speak"] as? String { return try nonEmpty(speak) }
            if let result = obj["result"] as? String { return try nonEmpty(result) }
            if let text = obj["text"] as? String { return try nonEmpty(text) }
        }

        if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let first = arr.first {
            if let answer = first["answer"] as? String { return try nonEmpty(answer) }
            if let text = first["text"] as? String { return try nonEmpty(text) }
        }

        if let plain = String(data: data, encoding: .utf8) {
            return try nonEmpty(plain)
        }

        throw AlanAPIError.decodingFailed
    }

    private func nonEmpty(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if trimmed.isEmpty { throw AlanAPIError.emptyResponse }
        return trimmed
    }

    // GET 쿼리로 들어갈 텍스트를 안정적으로 정리한다.
    // - 줄바꿈/중복 공백 축약
    // - 최대 길이 제한
    private func sanitizeForQuery(_ text: String, maxCharacters: Int) -> String {
        let compact = text
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if compact.count <= maxCharacters { return compact }
        return String(compact.prefix(maxCharacters))
    }
}
