//
//  ChatMessageRendering.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/21/26.
//

import SwiftUI

// MARK: - Overview
//
// 이 파일은 채팅 화면에서 “메시지 1개”를 그리는 렌더링 컴포넌트 모음입니다.
// - MessageBubbleView: ChatMessage(도메인 모델)를 받아 말풍선, 링크, 타임스탬프까지 구성합니다.
// - TypingBubbleView: 봇이 응답을 생성 중일 때 표시하는 타이핑 인디케이터입니다.
// - MarkdownBlockView: 서버 응답에 포함될 수 있는 간단한 마크다운(헤딩/불릿)을 화면용으로 렌더링합니다.
//
// 연동 위치
// - ChatRoomView에서 메시지 리스트를 그릴 때 MessageBubbleView/TypingBubbleView가 사용됩니다.
// - ChatTextProcessing(LinkSegmenter/TextCleaner)와 결합되어 링크 버튼 분리, 출처 표기 제거가 이 단계에서 마무리됩니다.

// 말풍선 모서리를 원하는 조합으로 만들기 위한 Shape입니다.
// - 좌/우 메시지의 꼬리 느낌을 “한쪽 하단 모서리만 0”으로 표현합니다.
// - SwiftUI의 기본 RoundedRectangle만으로는 이 형태를 만들기 어려워 커스텀 Path를 사용합니다.
struct ChatBubbleShape: Shape {
    var topLeft: CGFloat
    var topRight: CGFloat
    var bottomLeft: CGFloat
    var bottomRight: CGFloat
    func path(in rect: CGRect) -> Path {
        let tl = min(min(topLeft, rect.width / 2), rect.height / 2)
        let tr = min(min(topRight, rect.width / 2), rect.height / 2)
        let bl = min(min(bottomLeft, rect.width / 2), rect.height / 2)
        let br = min(min(bottomRight, rect.width / 2), rect.height / 2)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        p.addArc(
            center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
            radius: tr,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        p.addArc(
            center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
            radius: br,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        p.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        p.addArc(
            center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
            radius: bl,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        p.addArc(
            center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
            radius: tl,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        p.closeSubpath()
        return p
    }
}

// 채팅 메시지 1개를 말풍선으로 렌더링합니다.
// - author에 따라 좌/우 정렬, 배경색, 모서리 모양이 달라집니다.
// - 본문은 LinkSegmenter로 텍스트/링크를 분리하고,
//   텍스트는 TextCleaner로 한 번 더 정리한 뒤 MarkdownBlockView로 표시합니다.
struct MessageBubbleView: View {
    let message: ChatMessage

    // 타임스탬프 포맷을 매번 생성하지 않기 위해 static으로 재사용합니다.
    // DateFormatter는 생성 비용이 있어 반복 렌더링에서 성능 차이가 날 수 있습니다.
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter
    }()
    private let botAvatarSize: CGFloat = 25
    private let botAvatarTextSpacing: CGFloat = 10

    // 봇 아바타를 단순한 원형으로 표현합니다.
    // 실제 이미지 대신 Shape로 두면 테마 적용과 성능이 단순합니다.
    private var botAvatarCircle: some View {
        Circle()
            .fill(Color.pink.opacity(0.95))
            .frame(width: botAvatarSize, height: botAvatarSize)
            .overlay {
                Circle()
                    .stroke(Color.black.opacity(0.65), lineWidth: 7)
            }
    }

    // 말풍선 모서리 조합을 author에 따라 선택합니다.
    // - bot: 왼쪽 말풍선, 좌하단을 0으로 해서 꼬리 느낌
    // - guest: 오른쪽 말풍선, 우하단을 0으로 해서 꼬리 느낌
    private var bubbleClipShape: ChatBubbleShape {
        if message.author == .bot {
            return ChatBubbleShape(topLeft: 16, topRight: 16, bottomLeft: 0, bottomRight: 16)
        }
        return ChatBubbleShape(topLeft: 16, topRight: 16, bottomLeft: 16, bottomRight: 0)
    }

    // 바깥 HStack에서 좌/우 정렬을 결정합니다.
    // Spacer(minLength:)를 넣어 말풍선이 화면 끝까지 붙지 않게 여백을 확보합니다.
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if message.author == .bot {
                bubbleWithTimestamp
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubbleWithTimestamp
            }
        }
        .frame(maxWidth: .infinity, alignment: message.author == .bot ? .leading : .trailing)
    }

    // bot/guest가 다른 레이아웃을 가지므로 조건 분기합니다.
    // SwiftUI의 some View는 분기마다 타입이 달라지면 반환이 어려워 AnyView로 감쌉니다.
    private var bubbleWithTimestamp: some View {
        let timestampText = Text(Self.timestampFormatter.string(from: message.createdAt))
            .font(.caption2)
            .foregroundStyle(.secondary)
        if message.author == .bot {
            return AnyView(
                VStack(alignment: .leading, spacing: 6) {
                    // 이름 라벨과 아바타를 말풍선 위쪽에 배치한다.
                    // 아바타는 overlay로 얹어서 말풍선 위에 살짝 겹치도록 처리한다.
                    Text("게임봇")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.leading, botAvatarSize + botAvatarTextSpacing)
                        .offset(x: -8, y: 12)
                    bubble
                        .overlay(alignment: .topLeading) {
                            botAvatarCircle
                                .offset(x: 0, y: -17)
                        }
                    timestampText
                }
            )
        }
        return AnyView(
            VStack(alignment: .trailing, spacing: 4) {
                bubble
                timestampText
            }
        )
    }

    // 본문을 텍스트/링크 세그먼트로 분리해 렌더링합니다.
    // - 링크는 Link 버튼으로, 텍스트는 MarkdownBlockView로 표시해 탭/선택 동작을 분리합니다.
    private var bubble: some View {
        let segments = LinkSegmenter.segments(from: message.text)
        let bubbleAlignment: Alignment = (message.author == .bot) ? .leading : .trailing
        let stackAlignment: HorizontalAlignment = (message.author == .bot) ? .leading : .trailing
        return VStack(alignment: stackAlignment, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(segments) { segment in
                    switch segment.kind {
                    case .text(let value):
                        // 서버 응답에 출처 표기 등이 섞일 수 있어 표시 전에 한 번 더 정리한다.
                        let cleaned = TextCleaner.stripSourceMarkers(value)
                        if cleaned.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                            MarkdownBlockView(text: cleaned)
                        }
                    case .link(let url):
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                Image(systemName: "link")
                                    .imageScale(.small)
                                Text(linkTitle(for: url))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            .font(.callout.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(bubbleBackground)
        .clipShape(bubbleClipShape)
        .overlay {
            bubbleClipShape
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(radius: 0.7, y: 0.7)
        .frame(maxWidth: 520, alignment: bubbleAlignment)
    }

    // author에 따라 배경색을 구분합니다.
    // 색상 정책은 UI 레이어에서만 알고, 도메인 모델은 스타일을 몰라도 되게 합니다.
    private var bubbleBackground: Color {
        if message.author == .bot { return Color.white.opacity(0.12) }
        return Color.purple.opacity(0.50)
    }
    private func linkTitle(for url: URL) -> String {
        if let host = url.host, host.isEmpty == false { return host }
        return url.absoluteString
    }
}

// 봇이 응답 생성 중일 때 표시하는 타이핑 인디케이터입니다.
// - ChatRoomViewModel이 “요청 중” 상태를 올리면 ChatRoomView가 이 뷰를 추가로 렌더링합니다.
// - Timer로 점 애니메이션을 돌리며, onDisappear에서 반드시 정리해 중복 타이머를 막습니다.
struct TypingBubbleView: View {
    @State private var phase = 0
    // SwiftUI 생명주기와 연결되는 Timer 참조입니다.
    // 화면에서 사라질 때 invalidate하지 않으면 메모리/업데이트가 남을 수 있어 관리합니다.
    @State private var timer: Timer?
    var body: some View {
        HStack {
            bubble
            Spacer(minLength: 40)
        }
        .onAppear {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    private var bubble: some View {
        HStack(spacing: 6) {
            Dot(isOn: phase == 0)
            Dot(isOn: phase == 1)
            Dot(isOn: phase == 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
        .accessibilityLabel("챗봇이 입력 중")
    }

    // 타이핑 점 하나를 표현합니다.
    // phase 값에 따라 opacity를 바꾸고, animation은 값 변화에만 반응하도록 설정합니다.
    private struct Dot: View {
        let isOn: Bool
        var body: some View {
            Circle()
                .frame(width: 7, height: 7)
                .opacity(isOn ? 1.0 : 0.25)
                .animation(.easeInOut(duration: 0.25), value: isOn)
        }
    }
}

// 간단한 마크다운을 화면용 블록으로 렌더링합니다.
// 지원 범위
// - 헤딩: # ~ ######
// - 불릿: - , •
// - 나머지: 일반 텍스트(인라인 마크다운은 Text(.init())에 위임)
//
// 목적
// - 서버 응답이 줄바꿈/불릿을 포함해도 읽기 쉽게 보이도록 최소한의 파서를 둡니다.
struct MarkdownBlockView: View {
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(parseBlocks(from: text)) { block in
                switch block.kind {
                case .heading(let level, let content):
                    Text(content)
                        .font(headingFont(for: level))
                        .fontWeight(.semibold)
                        .padding(.top, level <= 2 ? 6 : 4)
                        .fixedSize(horizontal: false, vertical: true)
                case .bullet(let content):
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                            .font(.body.weight(.semibold))
                            .fixedSize(horizontal: true, vertical: true)
                        Text(.init(content))
                            .font(.body)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                case .text(let content):
                    Text(.init(content))
                        .font(.body)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .textSelection(.enabled)
        .foregroundStyle(.primary)
    }
    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1: return .title2
        case 2: return .title3
        case 3: return .headline
        default: return .subheadline
        }
    }
    private enum BlockKind: Equatable {
        case heading(level: Int, content: String)
        case bullet(content: String)
        case text(content: String)
    }
    private struct Block: Identifiable, Equatable {
        let id = UUID()
        let kind: BlockKind
    }

    // 줄 단위로 읽어서 heading/bullet/text 블록으로 분리합니다.
    // 빈 줄이 나오면 버퍼를 flush해서 문단 단위가 유지되게 합니다.
    private func parseBlocks(from input: String) -> [Block] {
        let lines = input.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [Block] = []
        var buffer: [String] = []
        func flushBufferIfNeeded() {
            let joined = buffer.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if joined.isEmpty == false {
                blocks.append(Block(kind: .text(content: joined)))
            }
            buffer.removeAll(keepingCapacity: true)
        }
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if let heading = parseHeading(line) {
                flushBufferIfNeeded()
                blocks.append(heading)
                continue
            }
            if let bullet = parseBullet(line) {
                flushBufferIfNeeded()
                blocks.append(bullet)
                continue
            }
            if line.isEmpty {
                flushBufferIfNeeded()
                continue
            }
            buffer.append(rawLine)
        }
        flushBufferIfNeeded()
        return blocks
    }
    // 헤딩은 '# ' 패턴을 정규식으로 파싱합니다.
    // level은 1~6 범위로 제한해 폰트 매핑을 단순하게 유지합니다.
    private func parseHeading(_ line: String) -> Block? {
        let pattern = #"^(#{1,6})\s+(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let nsLine = line as NSString
        let range = NSRange(location: 0, length: nsLine.length)
        guard let match = regex.firstMatch(in: line, range: range) else { return nil }
        guard match.numberOfRanges >= 3 else { return nil }
        let hashes = nsLine.substring(with: match.range(at: 1))
        let content = nsLine
            .substring(with: match.range(at: 2))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let level = min(max(hashes.count, 1), 6)
        return Block(kind: .heading(level: level, content: content))
    }
    // 불릿은 '- ' 또는 '• ' 두 케이스만 처리합니다.
    // 서버가 만든 목록이든 사용자 입력이든, 최소 규칙만으로 안정적으로 보여주는 목적입니다.
    private func parseBullet(_ line: String) -> Block? {
        if line.hasPrefix("- ") {
            let content = String(line.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
            return Block(kind: .bullet(content: content))
        }
        if line.hasPrefix("• ") {
            let content = String(line.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
            return Block(kind: .bullet(content: content))
        }
        return nil
    }
}
