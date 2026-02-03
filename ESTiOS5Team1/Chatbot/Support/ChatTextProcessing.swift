//
//  ChatTextProcessing.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/21/26.
//

import Foundation

// MARK: - Overview

/// 채팅 텍스트를 “표시 가능한 형태”로 정리하는 유틸 모음입니다.
///
/// 이 파일의 역할
/// - 서버 응답/사용자 입력에 섞일 수 있는 노이즈(출처 표기, 마크다운 링크 형태, 깨진 URL, 이스케이프 문자열)를 정리합니다.
/// - URL을 본문과 분리해, UI에서 링크 버튼(Link)과 텍스트 블록을 안정적으로 렌더링할 수 있게 합니다.
///
/// 연동 위치
/// - ChatMessageRendering: LinkSegmenter로 세그먼트 분리 후, TextCleaner로 최종 표시용 정리를 합니다.
/// - AlanAPIClient/서버 응답: 응답 포맷이 들쭉날쭉해도 화면이 깨지지 않도록 “방어적으로” 처리합니다.
///
/// 구현 선택 이유
/// - NSDataDetector: 정규식보다 URL 인식이 안정적이라 링크 추출에 사용합니다.
/// - 정리 규칙을 UI 밖으로 분리: 뷰가 커지지 않고, 규칙 변경 시 수정 포인트가 한 곳으로 모입니다.

// MARK: - Models

/// 텍스트를 “본문”과 “링크”로 나누기 위한 타입입니다.
///
/// UI에서 링크는 단순 문자열이 아니라 Link 뷰로 처리하는 편이
/// 탭 동작/접근성/표시가 자연스럽기 때문에 세그먼트로 분리합니다.
enum LinkSegmentKind: Equatable {
    case text(String)
    case link(URL)
}

/// LinkSegmenter의 결과를 ForEach로 그리기 위한 래퍼입니다.
///
/// Identifiable이 필요한 이유
/// - SwiftUI 리스트 렌더링에서 안정적인 diff를 위해 id가 필요합니다.
struct LinkSegment: Identifiable, Equatable {
    let id = UUID()
    let kind: LinkSegmentKind
}

// MARK: - LinkSegmenter

/// 문자열에서 URL을 찾아 텍스트/링크 세그먼트로 분리합니다.
///
/// 처리 순서
/// 1) TextCleaner.sanitizeMarkdownLinksAndSources로 마크다운 링크/출처 표기 등을 먼저 정리
/// 2) NSDataDetector로 URL을 검출해 링크를 분리
///
/// 먼저 정리하는 이유
/// - [title](url) 같은 형태가 남아 있으면 detector가 괄호/대괄호까지 포함해 링크를 잘못 잡는 경우가 있습니다.
enum LinkSegmenter {
    private static let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    /// 입력 텍스트를 렌더링 단위(텍스트/링크)로 분리합니다.
    ///
    /// detector 로드 실패 시에는 전체를 텍스트로 취급합니다.
    /// - 이 경우에도 UI가 깨지지 않고 최소한의 표시가 보장됩니다.
    static func segments(from input: String) -> [LinkSegment] {
        let sanitizedInput = TextCleaner.sanitizeMarkdownLinksAndSources(input)

        guard let detector = Self.detector else {
            return [LinkSegment(kind: .text(sanitizedInput))]
        }

        let nsText = sanitizedInput as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)

        let matches = detector
            .matches(in: sanitizedInput, options: [], range: fullRange)
            .filter { $0.resultType == .link && $0.url != nil }

        guard !matches.isEmpty else {
            return [LinkSegment(kind: .text(sanitizedInput))]
        }

        var result: [LinkSegment] = []
        var cursorIndex = 0

        for match in matches {
            guard let url = match.url else { continue }
            let range = match.range

            if range.location > cursorIndex {
                let prefix = nsText.substring(with: NSRange(location: cursorIndex, length: range.location - cursorIndex))
                result.append(LinkSegment(kind: .text(prefix)))
            }

            result.append(LinkSegment(kind: .link(url)))
            cursorIndex = range.location + range.length
        }

        if cursorIndex < nsText.length {
            let tail = nsText.substring(from: cursorIndex)
            result.append(LinkSegment(kind: .text(tail)))
        }

        return mergeAdjacentTextSegments(result)
    }

    /// 링크 검출 후 잘게 쪼개진 텍스트 세그먼트를 합칩니다.
    ///
    /// 이유
    /// - 렌더링 트리(뷰 개수)가 불필요하게 커지는 것을 줄입니다.
    /// - 텍스트 블록이 지나치게 분리되면 줄바꿈/문장 흐름이 어색해질 수 있습니다.
    private static func mergeAdjacentTextSegments(_ segments: [LinkSegment]) -> [LinkSegment] {
        var merged: [LinkSegment] = []
        for segment in segments {
            if case .text(let text) = segment.kind,
               let last = merged.last,
               case .text(let lastText) = last.kind {
                merged.removeLast()
                merged.append(LinkSegment(kind: .text(lastText + text)))
            } else {
                merged.append(segment)
            }
        }
        return merged
    }
}

// MARK: - TextCleaner

/// 서버 응답/사용자 입력을 화면 표시용으로 정리하는 유틸입니다.
///
/// sanitizeMarkdownLinksAndSources
/// - 링크 형태를 단순 URL로 정리하고, 출처 표기 같은 노이즈를 제거합니다.
/// stripSourceMarkers
/// - 렌더링 직전에 한 번 더 정리해서 화면이 지저분해지는 것을 막습니다.
///
/// 응답이 JSON 문자열로 감싸져 있는 경우도 있어(이스케이프 포함),
/// normalizeAlanEnvelopeForDisplay에서 여러 방식으로 “실제 텍스트”를 추출합니다.
enum TextCleaner {
    /// 마크다운 링크/출처 표기/깨진 URL 등을 정리합니다.
    ///
    /// 목적
    /// - detector가 URL을 안정적으로 잡게 함
    /// - 본문에 섞인 “출처 n” 같은 잔여 토큰을 줄여 UI 가독성을 확보
    static func sanitizeMarkdownLinksAndSources(_ input: String) -> String {
        var output = input
        output = normalizeBrokenUrls(output)
        output = output.replacingOccurrences(of: #"\[[^\]]*\]\((https?://[^)\s]+)\)"#, with: "$1", options: .regularExpression)
        output = normalizeBrokenUrls(output)
        output = addSchemeToWwwLinks(output)
        output = output.replacingOccurrences(of: #"\(\s*(https?://[^\s)]+)\s*\)\s*\.?"#, with: "$1", options: .regularExpression)
        output = output.replacingOccurrences(of: #"(?m)(https?://\S+)\s*\)\s*\.?"#, with: "$1", options: .regularExpression)

        let sourcePatterns = [
            #"\(출처\s*\d+\)"#,
            #"출처\(\s*\d+\s*\)"#,
            #"출처\s*\d+"#,
            #"\[\s*출처\s*\d+\s*\]"#,
            #"#출처\d+"#,
            #"【\d+†source】"#,
            #"\[\d+\]"#,
            #"\d+번째 출처"#,
            #"참고문헌\s*\d+"#
        ]
        for pattern in sourcePatterns {
            output = output.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }

        output = output.replacingOccurrences(of: #"\[\s*\]"#, with: "", options: .regularExpression)
        output = output.replacingOccurrences(of: #"\(\s*\)"#, with: "", options: .regularExpression)
        output = removeOrphanPunctuationLines(output)
        output = output.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 화면 표시 직전에 출처/빈 괄호 등의 잔여 토큰을 제거합니다.
    ///
    /// sanitize와 분리한 이유
    /// - 링크 세그먼트 분리에 필요한 정리와, 최종 표시 품질을 위한 정리는 타이밍이 다릅니다.
    /// - UI에서는 이 메서드를 한 번 더 적용해 “최종 텍스트”만 보여주게 합니다.
    static func stripSourceMarkers(_ input: String) -> String {
        var output = normalizeAlanEnvelopeForDisplay(input)
        let patterns = [
            #"\(출처\s*\d+\)"#,
            #"출처\(\s*\d+\s*\)"#,
            #"출처\s*\d+"#,
            #"\[\s*출처\s*\d+\s*\]"#,
            #"\[\s*\]"#,
            #"\(\s*\)"#
        ]
        for pattern in patterns {
            output = output.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        output = output.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        return removeOrphanPunctuationLines(output.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Alan 응답이 JSON/이스케이프/일반 문자열 어떤 형태로 오더라도 표시 가능한 텍스트를 뽑습니다.
    ///
    /// 여러 경로로 추출을 시도하는 이유
    /// - 서버 응답이 환경/버전에 따라 포맷이 달라질 수 있어, 단일 파서에 의존하면 UI가 쉽게 깨집니다.
    private static func normalizeAlanEnvelopeForDisplay(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if let extracted = extractTextFromJSONObject(trimmed) { return unescapeForDisplay(extracted) }
        if let unwrapped = decodeJSONStringIfNeeded(trimmed),
           let extracted = extractTextFromJSONObject(unwrapped) { return unescapeForDisplay(extracted) }
        if let extracted = extractContentByRegex(trimmed) { return unescapeForDisplay(extracted) }
        return unescapeForDisplay(trimmed)
    }

    /// 전체가 JSON string 형태(따옴표로 감싼 문자열)로 온 경우를 복원합니다.
    private static func decodeJSONStringIfNeeded(_ text: String) -> String? {
        guard text.hasPrefix("\""), text.hasSuffix("\""), text.count >= 2 else { return nil }
        guard let data = text.data(using: .utf8),
              let value = try? JSONSerialization.jsonObject(with: data) as? String else { return nil }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// JSON object에서 실제 텍스트 후보 키를 순서대로 탐색합니다.
    ///
    /// 키를 여러 개 보는 이유
    /// - 서버가 content/answer/text/speak/result 등 다양한 키로 텍스트를 줄 수 있습니다.
    private static func extractTextFromJSONObject(_ jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let keys = ["content", "answer", "text", "speak", "result", "message", "output"]
            for key in keys {
                if let val = obj[key] as? String, !val.isEmpty { return val }
            }
            if let action = obj["action"] as? [String: Any],
               let content = action["content"] as? String, !content.isEmpty {
                return content
            }
        }
        return nil
    }

    /// JSON 파싱이 실패할 때를 대비한 regex 기반 폴백입니다.
    ///
    /// 이유
    /// - 완전한 JSON이 아닌 문자열이 섞이면 JSONSerialization이 실패할 수 있습니다.
    /// - 이 경우에도 최소한 content를 뽑아 화면에 보여주기 위한 방어입니다.
    private static func extractContentByRegex(_ text: String) -> String? {
        let pattern = #""content"\s*:\s*"((?:\\.|[^"\\])*)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) else { return nil }
        return ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 화면 표시를 위해 대표적인 escape/HTML entity를 복원합니다.
    private static func unescapeForDisplay(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\\\", with: "\\")
            .replacingOccurrences(of: "\\t", with: "\t")
            .replacingOccurrences(of: "\\r", with: "\r")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }

    /// 줄바꿈으로 깨진 URL 조각을 붙입니다.
    private static func normalizeBrokenUrls(_ input: String) -> String {
        input.replacingOccurrences(of: #"(?m)(https?://[^\s]+)\s*\n\s*(/[^\s]+)"#, with: "$1$2", options: .regularExpression)
    }

    /// www.로 시작하는 링크에 스킴을 보정합니다.
    ///
    /// 이유
    /// - URL 생성이 실패하면 Link로 렌더링할 수 없어서, 최소한 https://를 붙여 성공 확률을 높입니다.
    private static func addSchemeToWwwLinks(_ input: String) -> String {
        input.replacingOccurrences(of: #"(?<!https://)(?<!http://)\b(www\.[A-Za-z0-9\.\-]+\.[A-Za-z]{2,})(/[^\s]*)?"#, with: "https://$1$2", options: .regularExpression)
    }

    /// 괄호만 남은 라인 같은 “의미 없는 줄”을 제거합니다.
    private static func removeOrphanPunctuationLines(_ input: String) -> String {
        input.replacingOccurrences(of: #"(?m)^\s*[\(\)]\s*\.?\s*$\n?"#, with: "", options: .regularExpression)
    }

    /// 검색 결과/출처 아티팩트처럼 화면을 지저분하게 만드는 라인을 정리합니다.
    ///
    /// 사용 시점
    /// - 특정 응답이 링크만 잔뜩 붙거나, 불필요한 라인이 섞이는 케이스를 대비한 보조 유틸입니다.
    static func stripSearchResultArtifacts(_ input: String) -> String {
        var output = input
        output = normalizeBrokenUrls(output)
        let patterns = [
            #"(?m)^\s*https?://\S+\s*$\n?"#,
            #"(?m)^\s*www\.\S+\s*$\n?"#,
            #"(?m)^\s*(?:[a-z0-9](?:[a-z0-9\-]{0,61}[a-z0-9])?\.)+[a-z]{2,}(?:/[^\s]*)?\s*$\n?"#,
            #"(?m)^\s*-?(?:%[0-9A-Fa-f]{2}){3,}[^\\s]*\\s*$\n?"#,
            #"(?m)^\s*출처\s*[:：]?\s*$\n?"#,
            #"(?m)^\s*\[\d+\]\s*$\n?"#,
            #"(?m)^참고\s*:\s*.*\n?"#,
            #"(?m)^이미지\s*출처\s*:.*\n?"#
        ]
        for pattern in patterns {
            output = output.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Extensions

/// 문자열 트리밍을 반복하지 않기 위한 보조 프로퍼티입니다.
///
/// 사용처가 많아지면 호출부 코드가 길어지므로, 확장으로 짧게 유지합니다.
private extension String {
    var trimmedValue: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedIsEmpty: Bool { trimmedValue.isEmpty }
}
