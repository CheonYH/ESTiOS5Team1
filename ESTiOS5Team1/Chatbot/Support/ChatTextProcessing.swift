//
//  ChatTextProcessing.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/21/26.
//

import Foundation

// MARK: - Models
enum LinkSegmentKind: Equatable {
    case text(String)
    case link(URL)
}

struct LinkSegment: Identifiable, Equatable {
    let id = UUID()
    let kind: LinkSegmentKind
}

// MARK: - LinkSegmenter
enum LinkSegmenter {
    private static let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

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
enum TextCleaner {
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

    private static func normalizeAlanEnvelopeForDisplay(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if let extracted = extractTextFromJSONObject(trimmed) { return unescapeForDisplay(extracted) }
        if let unwrapped = decodeJSONStringIfNeeded(trimmed),
           let extracted = extractTextFromJSONObject(unwrapped) { return unescapeForDisplay(extracted) }
        if let extracted = extractContentByRegex(trimmed) { return unescapeForDisplay(extracted) }
        return unescapeForDisplay(trimmed)
    }

    private static func decodeJSONStringIfNeeded(_ text: String) -> String? {
        guard text.hasPrefix("\""), text.hasSuffix("\""), text.count >= 2 else { return nil }
        guard let data = text.data(using: .utf8),
              let value = try? JSONSerialization.jsonObject(with: data) as? String else { return nil }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

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

    private static func extractContentByRegex(_ text: String) -> String? {
        let pattern = #""content"\s*:\s*"((?:\\.|[^"\\])*)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) else { return nil }
        return ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

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

    private static func normalizeBrokenUrls(_ input: String) -> String {
        input.replacingOccurrences(of: #"(?m)(https?://[^\s]+)\s*\n\s*(/[^\s]+)"#, with: "$1$2", options: .regularExpression)
    }

    private static func addSchemeToWwwLinks(_ input: String) -> String {
        input.replacingOccurrences(of: #"(?<!https://)(?<!http://)\b(www\.[A-Za-z0-9\.\-]+\.[A-Za-z]{2,})(/[^\s]*)?"#, with: "https://$1$2", options: .regularExpression)
    }

    private static func removeOrphanPunctuationLines(_ input: String) -> String {
        input.replacingOccurrences(of: #"(?m)^\s*[\(\)]\s*\.?\s*$\n?"#, with: "", options: .regularExpression)
    }

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
private extension String {
    var trimmedValue: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedIsEmpty: Bool { trimmedValue.isEmpty }
}
