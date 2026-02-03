//
//  AlanAPIClient.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation

// MARK: - Overview

/// Alan API 서버와 통신하는 얇은 네트워크 클라이언트입니다.
///
/// 이 파일의 역할
/// - ViewModel에서 URL 구성/요청/응답 파싱을 분리해, 화면 로직이 네트워크 세부사항을 모르도록 합니다.
/// - 응답 포맷이 고정되지 않았을 때(answer/speak/result/text 등) 파싱 규칙을 한 곳에서만 관리합니다.
///
/// 연동 위치
/// - ChatRoomViewModel: 메시지 전송 시 ask를 호출하고, 방 전환/새 채팅 시 resetState를 호출해 서버 문맥을 리셋합니다.
/// - SettingsModels: endpoint(baseUrl)를 읽어 Configuration.baseUrl로 주입합니다.
///
/// 구현 선택 이유
/// - GET query 방식은 서버 스펙에 맞춘 것입니다. 대신 URL 길이 제한 위험이 있어 sanitizeForQuery로 상한을 둡니다.
/// - LocalizedError로 에러 메시지를 단일 문자열로 노출 가능하게 해서, UI에서 별도 매핑 없이 표시하기 쉽습니다.

struct AlanAPIClient {

    /// 클라이언트 구성 값입니다.
    ///
    /// baseUrl을 외부에서 주입받는 이유
    /// - SettingsModels(AppSettings/AlanSettings)에서 읽은 endpoint를 그대로 반영할 수 있습니다.
    /// - 테스트에서 임의 서버로 바꾸기 쉽습니다.
    struct Configuration: Sendable {
        let baseUrl: URL
        init(baseUrl: URL) {
            self.baseUrl = baseUrl
        }
    }

    /// Alan API 통신 중 발생 가능한 오류 타입입니다.
    ///
    /// badStatus에 body를 같이 넣는 이유
    /// - 서버 오류/스펙 변경 시 원인을 파악할 수 있는 근거를 남기기 위함입니다.
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

    /// GET query에 넣을 content 최대 길이입니다.
    ///
    /// 이유
    /// - URL 길이 제한/인코딩 증가로 요청 실패가 발생할 수 있어 상한을 둡니다.
    /// - 너무 긴 프롬프트는 서버/모델 품질에도 악영향이 있어, 최소한의 방어로 작동합니다.
    private let maxContentCharactersForGET: Int = 1200

    init(configuration: Configuration, urlSession: URLSession = .shared) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    /// 질문을 전송하고 텍스트 응답을 반환합니다.
    ///
    /// 요청 스펙
    /// - GET /api/v1/question?content=...&client_id=...
    ///
    /// clientId의 의미
    /// - 서버가 대화 문맥(세션)을 구분하는 키입니다.
    /// - 방 단위로 문맥이 섞이지 않게 하려면, ViewModel에서 방의 식별자/설정값과 일관되게 전달해야 합니다.
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

    /// 서버 측 대화 상태를 초기화합니다.
    ///
    /// 요청 스펙
    /// - DELETE /api/v1/reset-state
    /// - body: { "client_id": ... }
    ///
    /// 사용하는 이유
    /// - 새 채팅 시작/방 전환 시 이전 문맥이 섞이면 답변 품질이 크게 떨어질 수 있습니다.
    /// - ViewModel은 "방 최초 진입" 같은 시점에만 호출해 불필요한 리셋을 피합니다.
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

    /// 응답을 텍스트로 정규화합니다.
    ///
    /// 이유
    /// - 서버가 상황에 따라 answer/speak/result/text 등 다양한 키로 응답할 수 있습니다.
    /// - 배열/문자열로 떨어지는 케이스도 대비해 파싱 순서를 고정해 둡니다.
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

    /// 빈 응답을 오류로 처리합니다.
    ///
    /// 이유
    /// - 네트워크는 성공(200)인데 본문이 비어 있으면 UI에서는 "응답 없음"으로 보이기 쉽습니다.
    /// - 이 케이스를 명확한 에러로 분리하면 재시도/로그 근거가 됩니다.
    private func nonEmpty(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if trimmed.isEmpty { throw AlanAPIError.emptyResponse }
        return trimmed
    }

    /// GET query에 넣기 전 content를 축약/정리합니다.
    ///
    /// 수행 내용
    /// - 연속 공백을 1칸으로 압축
    /// - 앞뒤 공백 제거
    /// - 최대 길이 초과 시 prefix로 잘라냄
    ///
    /// 이 로직을 클라이언트에 두는 이유
    /// - 호출부(ViewModel)가 네트워크 전송 제약(URL 길이)을 몰라도 되게 하기 위함입니다.
    private func sanitizeForQuery(_ text: String, maxCharacters: Int) -> String {
        let compact = text
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if compact.count <= maxCharacters { return compact }
        return String(compact.prefix(maxCharacters))
    }
}
