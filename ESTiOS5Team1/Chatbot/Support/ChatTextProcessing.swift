//
//  ChatTextProcessing.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/21/26.
//

import Foundation

// UI에서 텍스트를 "일반 문자열"과 "링크"로 분리해서 렌더링하기 위한 타입들이다.
// 링크는 버튼/탭 가능한 형태로 보여주고, 일반 텍스트는 그대로 보여준다.
enum LinkSegmentKind: Equatable {
    case text(String)
    case link(URL)
}

struct LinkSegment: Identifiable, Equatable {
    let id = UUID()
    let kind: LinkSegmentKind
}

// 입력 문자열에서 URL을 찾아 텍스트/링크 구간으로 나눈다.
// URL 검출에는 NSDataDetector를 사용한다.
// 검출 안정성을 위해, 먼저 마크다운 링크 형태나 출처 표기 등을 정리한 문자열을 대상으로 한다.
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

            // 링크 앞쪽에 일반 텍스트가 있으면 먼저 추가한다.
            if range.location > cursorIndex {
                let prefix = nsText.substring(
                    with: NSRange(location: cursorIndex, length: range.location - cursorIndex)
                )
                result.append(LinkSegment(kind: .text(prefix)))
            }

            // 링크 구간 추가
            result.append(LinkSegment(kind: .link(url)))
            cursorIndex = range.location + range.length
        }

        // 마지막 링크 뒤에 남은 텍스트가 있으면 추가한다.
        if cursorIndex < nsText.length {
            let tail = nsText.substring(from: cursorIndex)
            result.append(LinkSegment(kind: .text(tail)))
        }

        // 텍스트-텍스트가 연달아 생기면 하나로 합쳐 렌더링을 단순화한다.
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

// 서버 응답이나 모델 출력에는 링크/출처 표기, 줄바꿈으로 깨진 URL 등이 섞일 수 있다.
// 이 유틸은 "링크 검출과 화면 표시"를 안정적으로 만들기 위한 전처리를 담당한다.
enum TextCleaner {
    static func sanitizeMarkdownLinksAndSources(_ input: String) -> String {
        var output = input

        // URL이 줄바꿈으로 깨진 형태를 먼저 복원한다.
        output = normalizeBrokenUrls(output)

        // [title](https://...) 형태의 마크다운 링크는 title을 제거하고 URL만 남긴다.
        output = output.replacingOccurrences(
            of: #"\[[^\]]*\]\((https?://[^)\s]+)\)"#,
            with: "$1",
            options: .regularExpression
        )

        // www.* 형태가 들어오면 scheme을 붙여 detector가 링크로 잡기 쉽게 만든다.
        output = normalizeBrokenUrls(output)
        output = addSchemeToWwwLinks(output)

        // (https://...) 또는 (https://...). 처럼 괄호/마침표가 붙은 형태를 정리한다.
        output = output.replacingOccurrences(
            of: #"\(\s*(https?://[^\s)]+)\s*\)\s*\.?"#,
            with: "$1",
            options: .regularExpression
        )

        // 링크 뒤에 괄호만 남는 케이스를 정리한다: "... https://x ) ." 같은 조합
        output = output.replacingOccurrences(
            of: #"(?m)(https?://\S+)\s*\)\s*\.?"#,
            with: "$1",
            options: .regularExpression
        )

        // "(출처 1)", "출처(1)" 같은 표기는 화면에서 불필요하므로 제거한다.
        let sourcePatterns: [String] = [
            #"\(출처\s*\d+\)"#,
            #"출처\(\s*\d+\s*\)"#,
            #"출처\s*\d+"#,
            #"\[\s*출처\s*\d+\s*\]"#
        ]

        for pattern in sourcePatterns {
            output = output.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }

        // 빈 대괄호/빈 괄호 제거
        output = output.replacingOccurrences(of: #"\[\s*\]"#, with: "", options: .regularExpression)
        output = output.replacingOccurrences(of: #"\(\s*\)"#, with: "", options: .regularExpression)

        // 링크가 버튼으로 분리된 뒤 남는 고아 문장부호 라인을 정리한다.
        output = removeOrphanPunctuationLines(output)

        // 공백 정리
        output = output.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)

        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // "(출처 1)" 같은 마커만 제거하고 싶을 때 사용하는 함수
    // ViewModel에서 서버 응답을 표시하기 전에 호출하는 용도다.
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

    // URL이 줄바꿈으로 끊겨 있는 형태를 최대한 복원한다.
    // 예: https://domain\n/path -> https://domain/path
    private static func normalizeBrokenUrls(_ input: String) -> String {
        var output = input

        output = output.replacingOccurrences(
            of: #"(?m)(https?://[^\s]+)\s*\n\s*(/[^\s]+)"#,
            with: "$1$2",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"(?m)\b(www\.[A-Za-z0-9\.\-]+\.[A-Za-z]{2,})\s*\n\s*(/[^\s]+)"#,
            with: "https://$1$2",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"(?m)\b(www\.[A-Za-z0-9\.\-]+\.[A-Za-z]{2,})\s*\n\s*/\s*\n\s*([^\s]+)"#,
            with: "https://$1/$2",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"(?m)(https?://[^\s]+)\s*\n\s*/\s*\n\s*([^\s]+)"#,
            with: "$1/$2",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"(?m)\b([A-Za-z0-9\.\-]+\.[A-Za-z]{2,})\s*\n\s*-?(%[0-9A-Fa-f]{2}[^\s]*)"#,
            with: "https://$1/$2",
            options: .regularExpression
        )

        return output
    }

    // "www.example.com"처럼 scheme이 없는 링크는 detector가 잘 못 잡는 경우가 있어
    // https://를 붙여준다.
    private static func addSchemeToWwwLinks(_ input: String) -> String {
        input.replacingOccurrences(
            of: #"(?<!https://)(?<!http://)\b(www\.[A-Za-z0-9\.\-]+\.[A-Za-z]{2,})(/[^\s]*)?"#,
            with: "https://$1$2",
            options: .regularExpression
        )
    }

    // 링크 분리/정리 과정에서 남을 수 있는 고아 라인을 제거한다.
    // 예: "(" 한 줄만 남는 경우, "."만 남는 경우 등
    private static func removeOrphanPunctuationLines(_ input: String) -> String {
        var output = input

        output = output.replacingOccurrences(
            of: #"(?m)^\s*[\(\)]\s*\.?\s*$\n?"#,
            with: "",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"(?m)^\s*[\.\u00B7•\-–—]+\s*$\n?"#,
            with: "",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"\)\s*\n\s*\."#,
            with: ")",
            options: .regularExpression
        )

        output = output.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)

        return output
    }
}

// 검색 결과 텍스트처럼 URL/도메인 라인이 단독으로 섞여 들어오는 경우를 정리할 때 사용한다.
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
