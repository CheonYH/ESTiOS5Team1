//
//  ChatTextProcessing.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/21/26.
//

import Foundation

enum LinkSegmentKind: Equatable {
    case text(String)
    case link(URL)
}

struct LinkSegment: Identifiable, Equatable {
    let id = UUID()
    let kind: LinkSegmentKind
}

enum LinkSegmenter {
    static func segments(from input: String) -> [LinkSegment] {
        let sanitizedInput = TextCleaner.sanitizeMarkdownLinksAndSources(input)

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return [LinkSegment(kind: .text(sanitizedInput))]
        }

        let nsText = sanitizedInput as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)

        let matches = detector
            .matches(in: sanitizedInput, options: [], range: fullRange)
            .filter { $0.resultType == .link && $0.url != nil }

        guard matches.isEmpty == false else {
            return [LinkSegment(kind: .text(sanitizedInput))]
        }

        var result: [LinkSegment] = []
        var cursorIndex = 0

        for match in matches {
            guard let url = match.url else { continue }
            let range = match.range

            if range.location > cursorIndex {
                let prefix = nsText.substring(
                    with: NSRange(location: cursorIndex, length: range.location - cursorIndex)
                )
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

enum TextCleaner {
    static func sanitizeMarkdownLinksAndSources(_ input: String) -> String {
        var output = input

        // URL이 줄바꿈으로 깨진 형태를 먼저 복원
        output = normalizeBrokenUrls(output)

        // [title](https://...) -> https://...
        output = output.replacingOccurrences(
            of: #"\[[^\]]*\]\((https?://[^)\s]+)\)"#,
            with: "$1",
            options: .regularExpression
        )

        // www.* 형태에 scheme 부여 (detector 안정화)
        output = normalizeBrokenUrls(output)
        output = addSchemeToWwwLinks(output)

        // (https://...) 또는 (https://...).  형태에서 괄호/마침표 제거
        output = output.replacingOccurrences(
            of: #"\(\s*(https?://[^\s)]+)\s*\)\s*\.?"#,
            with: "$1",
            options: .regularExpression
        )

        // 링크 뒤에 괄호만 남는 케이스를 사전에 정리: "... https://x ) ." 같은 조합
        output = output.replacingOccurrences(
            of: #"(?m)(https?://\S+)\s*\)\s*\.?"#,
            with: "$1",
            options: .regularExpression
        )

        let sourcePatterns: [String] = [
            #"\(출처\s*\d+\)"#,
            #"출처\(\s*\d+\s*\)"#,
            #"출처\s*\d+"#,
            #"\[\s*출처\s*\d+\s*\]"#
        ]

        for pattern in sourcePatterns {
            output = output.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }

        // 빈 마크/빈 괄호 제거
        output = output.replacingOccurrences(of: #"\[\s*\]"#, with: "", options: .regularExpression)
        output = output.replacingOccurrences(of: #"\(\s*\)"#, with: "", options: .regularExpression)

        // 고아 문장부호 라인/깨진 조합 정리
        output = removeOrphanPunctuationLines(output)

        // 공백 정리
        output = output.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)

        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func stripSourceMarkers(_ input: String) -> String {
        var output = input

        let patterns: [String] = [
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
        output = output.trimmingCharacters(in: .whitespacesAndNewlines)

        return removeOrphanPunctuationLines(output)
    }

    private static func normalizeBrokenUrls(_ input: String) -> String {
        var output = input

        // 1) https://domain\n/path  -> join
        output = output.replacingOccurrences(
            of: #"(?m)(https?://[^\s]+)\s*\n\s*(/[^\s]+)"#,
            with: "$1$2",
            options: .regularExpression
        )

        // 2) www.domain\n/path  -> https://www.domain/path
        output = output.replacingOccurrences(
            of: #"(?m)\b(www\.[A-Za-z0-9\.\-]+\.[A-Za-z]{2,})\s*\n\s*(/[^\s]+)"#,
            with: "https://$1$2",
            options: .regularExpression
        )

        // 3) www.domain\n/\npath  (슬래시가 단독 라인)
        output = output.replacingOccurrences(
            of: #"(?m)\b(www\.[A-Za-z0-9\.\-]+\.[A-Za-z]{2,})\s*\n\s*/\s*\n\s*([^\s]+)"#,
            with: "https://$1/$2",
            options: .regularExpression
        )

        // 4) https://domain\n/\npath  (슬래시가 단독 라인)
        output = output.replacingOccurrences(
            of: #"(?m)(https?://[^\s]+)\s*\n\s*/\s*\n\s*([^\s]+)"#,
            with: "$1/$2",
            options: .regularExpression
        )

        // 5) domain\n-%EC... (퍼센트 인코딩이 줄바꿈으로 분리된 케이스)
        output = output.replacingOccurrences(
            of: #"(?m)\b([A-Za-z0-9\.\-]+\.[A-Za-z]{2,})\s*\n\s*-?(%[0-9A-Fa-f]{2}[^\s]*)"#,
            with: "https://$1/$2",
            options: .regularExpression
        )

        return output
    }

    private static func addSchemeToWwwLinks(_ input: String) -> String {
        input.replacingOccurrences(
            of: #"(?<!https://)(?<!http://)\b(www\.[A-Za-z0-9\.\-]+\.[A-Za-z]{2,})(/[^\s]*)?"#,
            with: "https://$1$2",
            options: .regularExpression
        )
    }

    private static func removeOrphanPunctuationLines(_ input: String) -> String {
        var output = input

        // 링크가 버튼으로 분리된 뒤 남는 고아 괄호 라인 제거: "(" / ")" / ")." / "(."
        output = output.replacingOccurrences(
            of: #"(?m)^\s*[\(\)]\s*\.?\s*$\n?"#,
            with: "",
            options: .regularExpression
        )

        // ".", "•", "-" 같은 고아 문장부호 라인 제거
        output = output.replacingOccurrences(
            of: #"(?m)^\s*[\.\u00B7•\-–—]+\s*$\n?"#,
            with: "",
            options: .regularExpression
        )

        // ") \n ." 패턴 보정
        output = output.replacingOccurrences(
            of: #"\)\s*\n\s*\."#,
            with: ")",
            options: .regularExpression
        )

        // 연속 개행 정리
        output = output.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)

        return output
    }
}

extension TextCleaner {
    static func stripSearchResultArtifacts(_ input: String) -> String {
        var output = input

        output = normalizeBrokenUrls(output)

        output = output.replacingOccurrences(
            of: #"(?m)^\s*https?://\S+\s*$\n?"#,
            with: "",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"(?m)^\s*www\.\S+\s*$\n?"#,
            with: "",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"(?m)^\s*(?:[a-z0-9](?:[a-z0-9\-]{0,61}[a-z0-9])?\.)+[a-z]{2,}(?:/[^\s]*)?\s*$\n?"#,
            with: "",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"(?m)^\s*-?(?:%[0-9A-Fa-f]{2}){3,}[^\s]*\s*$\n?"#,
            with: "",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"(?m)^\s*출처\s*[:：]?\s*$\n?"#,
            with: "",
            options: .regularExpression
        )

        output = output.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)

        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
