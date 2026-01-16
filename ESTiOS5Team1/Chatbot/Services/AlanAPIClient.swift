//
//  AlanAPIClient.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation

struct AlanAPIClient {
    struct Configuration: Sendable {
        /// e.g. https://kdt-api-function.azurewebsites.net
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
            case .invalidUrl: return "Invalid Alan API URL."
            case .badStatus(let code, let body):
                return "Alan API failed. status=\(code), body=\(body)"
            case .emptyResponse: return "Alan API returned empty response."
            case .decodingFailed: return "Failed to decode Alan API response."
            }
        }
    }

    private let configuration: Configuration
    private let urlSession: URLSession

    init(configuration: Configuration, urlSession: URLSession = .shared) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    func ask(content: String, clientId: String) async throws -> String {
        var components = URLComponents(url: configuration.baseUrl, resolvingAgainstBaseURL: false)
        components?.path = "/api/v1/question"
        components?.queryItems = [
            URLQueryItem(name: "content", value: content),
            URLQueryItem(name: "client_id", value: clientId)
        ]

        guard let urlValue = components?.url else { throw AlanAPIError.invalidUrl }

        var request = URLRequest(url: urlValue)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (dataValue, responseValue) = try await urlSession.data(for: request)
        return try Self.parseAlanResponse(data: dataValue, response: responseValue)
    }

    func resetState(clientId: String) async throws -> String {
        guard let urlValue = URL(string: "/api/v1/reset-state", relativeTo: configuration.baseUrl) else {
            throw AlanAPIError.invalidUrl
        }

        var request = URLRequest(url: urlValue)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ResetBody(clientId: clientId))

        let (dataValue, responseValue) = try await urlSession.data(for: request)
        return try Self.parseAlanResponse(data: dataValue, response: responseValue)
    }

    // MARK: - Private

    private struct ResetBody: Encodable {
        let clientId: String
        enum CodingKeys: String, CodingKey { case clientId = "client_id" }
    }

    private struct AlanEnvelope: Decodable {
        struct Action: Decodable {
            let name: String?
            let speak: String?
        }

        let action: Action?
        let content: String?
    }

    private static func parseAlanResponse(data: Data, response: URLResponse) throws -> String {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        if (200...299).contains(statusCode) == false {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw AlanAPIError.badStatus(statusCode, bodyText)
        }

        // 1) "JSON string" 형태:  "hello"
        if let decodedString = try? JSONDecoder().decode(String.self, from: data) {
            let trimmed = decodedString.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { throw AlanAPIError.emptyResponse }
            return trimmed
        }

        // 2) "JSON object" 형태: {"action": {...}, "content": "..."}
        if let decodedObject = try? JSONDecoder().decode(AlanEnvelope.self, from: data) {
            let content = (decodedObject.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if content.isEmpty == false {
                return content
            }

            let speak = (decodedObject.action?.speak ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if speak.isEmpty == false {
                return speak
            }

            throw AlanAPIError.emptyResponse
        }

        // 3) plain text fallback
        if let plain = String(data: data, encoding: .utf8) {
            let trimmed = plain.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { throw AlanAPIError.emptyResponse }
            return trimmed
        }

        throw AlanAPIError.decodingFailed
    }
}
