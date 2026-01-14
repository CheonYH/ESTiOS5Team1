//
//  AlanAPIClient.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation

enum AlanAPIError: Error {
    case invalidEndpoint
    case invalidUrl
    case badStatusCode(Int)
    case emptyResponse
}

struct AlanResetRequest: Encodable {
    let clientIdentifier: String
    enum CodingKeys: String, CodingKey { case clientIdentifier = "client_id" }
}

final class AlanAPIClient {
    func ask(
        apiKey: String,
        endpoint: String,
        authHeaderField: String?,
        authHeaderPrefix: String?,
        clientIdentifier: String,
        content: String
    ) async throws -> String {
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw AlanAPIError.invalidEndpoint
        }

        urlComponents.path = "/api/v1/question"
        urlComponents.queryItems = [
            URLQueryItem(name: "content", value: content),
            URLQueryItem(name: "client_id", value: clientIdentifier)
        ]

        guard let requestUrl = urlComponents.url else { throw AlanAPIError.invalidUrl }

        var urlRequest = URLRequest(url: requestUrl)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let authHeaderField, !authHeaderField.isEmpty, !apiKey.isEmpty {
            let prefixValue = authHeaderPrefix ?? ""
            urlRequest.setValue(prefixValue + apiKey, forHTTPHeaderField: authHeaderField)
        }

        let (dataValue, responseValue) = try await URLSession.shared.data(for: urlRequest)

        if let httpResponse = responseValue as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw AlanAPIError.badStatusCode(httpResponse.statusCode)
        }

        if let textValue = String(data: dataValue, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !textValue.isEmpty {
            return textValue
        }

        throw AlanAPIError.emptyResponse
    }

    func reset(
        apiKey: String,
        endpoint: String,
        authHeaderField: String?,
        authHeaderPrefix: String?,
        clientIdentifier: String
    ) async throws -> String {
        guard let baseUrl = URL(string: endpoint) else { throw AlanAPIError.invalidEndpoint }
        let requestUrl = baseUrl.appendingPathComponent("/api/v1/reset-state")

        var urlRequest = URLRequest(url: requestUrl)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let authHeaderField, !authHeaderField.isEmpty, !apiKey.isEmpty {
            let prefixValue = authHeaderPrefix ?? ""
            urlRequest.setValue(prefixValue + apiKey, forHTTPHeaderField: authHeaderField)
        }

        urlRequest.httpBody = try JSONEncoder().encode(
            AlanResetRequest(clientIdentifier: clientIdentifier)
        )

        let (dataValue, responseValue) = try await URLSession.shared.data(for: urlRequest)

        if let httpResponse = responseValue as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw AlanAPIError.badStatusCode(httpResponse.statusCode)
        }

        if let textValue = String(data: dataValue, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !textValue.isEmpty {
            return textValue
        }

        throw AlanAPIError.emptyResponse
    }
}
