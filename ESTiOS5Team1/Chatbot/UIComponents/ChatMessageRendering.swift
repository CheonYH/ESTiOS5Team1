//
//  ChatMessageRendering.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/21/26.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter
    }()

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

    private var bubbleWithTimestamp: some View {
        let stackAlignment: HorizontalAlignment = (message.author == .bot) ? .leading : .trailing

        return VStack(alignment: stackAlignment, spacing: 4) {
            bubble
            Text(Self.timestampFormatter.string(from: message.createdAt))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var bubble: some View {
        let segments = LinkSegmenter.segments(from: message.text)
        let bubbleAlignment: Alignment = (message.author == .bot) ? .leading : .trailing
        let stackAlignment: HorizontalAlignment = (message.author == .bot) ? .leading : .trailing

        return VStack(alignment: stackAlignment, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(segments) { segment in
                    switch segment.kind {
                    case .text(let value):
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 0.7, y: 0.7)
        .frame(maxWidth: 520, alignment: bubbleAlignment)
    }

    private var bubbleBackground: Color {
        if message.author == .bot { return Color.white.opacity(0.12) }
        return Color.purple.opacity(0.50)
    }

    private func linkTitle(for url: URL) -> String {
        if let host = url.host, host.isEmpty == false { return host }
        return url.absoluteString
    }
}

struct TypingBubbleView: View {
    @State private var phase = 0
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
        .accessibilityLabel("Bot is typing")
    }

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
