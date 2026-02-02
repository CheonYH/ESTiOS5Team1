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

    private func sanitizeForQuery(_ text: String, maxCharacters: Int) -> String {
        let compact = text
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if compact.count <= maxCharacters { return compact }
        return String(compact.prefix(maxCharacters))
    }
}
