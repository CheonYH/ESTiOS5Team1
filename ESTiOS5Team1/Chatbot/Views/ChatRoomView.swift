//
//  ChatRoomView.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import SwiftUI
import UIKit

struct ChatRoomView: View {
    @StateObject private var roomViewModel: ChatRoomViewModel

    @ObservedObject private var roomsViewModel: ChatRoomsViewModel
    @State private var isPresentingRooms = false

    @FocusState private var isComposerFocused: Bool

    @State private var keyboardHeight: CGFloat = 0

    private let bottomAnchorId = "bottom_anchor"

    init(
        room: ChatRoom,
        store: ChatLocalStore,
        roomsViewModel: ChatRoomsViewModel
    ) {
        _roomViewModel = StateObject(
            wrappedValue: ChatRoomViewModel(
                room: room,
                store: store,
                alanEndpointOverride: "https://kdt-api-function.azurewebsites.net",
                alanClientKeyOverride: "e8c9e9ca-92ba-408b-8272-0505933a649f"
            )
        )
        self.roomsViewModel = roomsViewModel
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                messagesList
            }
            .preferredColorScheme(.dark)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                composerBar
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.clear)
            }
            .navigationTitle(roomViewModel.room.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await roomsViewModel.startNewConversation()
                            await roomViewModel.reload(room: roomsViewModel.defaultRoom)
                            focusComposerSoon()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(playNowTint)
                    .accessibilityLabel("Start new chat")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingRooms = true
                    } label: {
                        Image(systemName: "text.bubble")
                    }
                    .tint(playNowTint)
                }
            }
            .sheet(isPresented: $isPresentingRooms) {
                ChatRoomsView(roomsViewModel: roomsViewModel) { selectedRoom in
                    isPresentingRooms = false
                    Task {
                        await roomViewModel.reload(room: selectedRoom)
                        focusComposerSoon()
                    }
                }
            }
            .task {
                await roomViewModel.load()
                focusComposerSoon()
            }
            .onAppear {
                focusComposerSoon()
            }
            // 키보드 프레임 변경(등장/사라짐/높이 변경) 통합 처리
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                handleKeyboardWillChangeFrame(notification)
            }
        }
    }

    private var playNowTint: Color { .purple }

    private func focusComposerSoon() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            isComposerFocused = true
        }
    }

    private func handleKeyboardWillChangeFrame(_ notification: Notification) {
        guard let endFrameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        let endFrame = endFrameValue.cgRectValue
        let screenHeight = UIScreen.main.bounds.height

        // endFrame이 화면 바깥(아래)로 내려가면 키보드 hidden 상태로 판단
        let isKeyboardHidden = endFrame.origin.y >= screenHeight
        let newHeight: CGFloat = isKeyboardHidden ? 0 : endFrame.height

        keyboardHeight = newHeight
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(roomViewModel.messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.identifier)
                    }

                    if roomViewModel.isSending {
                        TypingBubbleView()
                            .transition(.opacity)
                    }

                    if let errorMessage = roomViewModel.errorMessage {
                        Text("⚠️ \(errorMessage)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(bottomAnchorId)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 4)
            }
            .scrollDismissesKeyboard(.interactively)
            .task {
                scrollToBottom(proxy: proxy, animated: false)
            }
            .onChange(of: roomViewModel.messages) { _, _ in
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onChange(of: roomViewModel.isSending) { _, _ in
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onChange(of: isComposerFocused) { _, focused in
                guard focused else { return }
                scrollToBottom(proxy: proxy, animated: true)
            }
            // 키보드가 올라갈 때/내려갈 때 모두 “레이아웃 반영 후” 바닥으로 재정렬
            .onChange(of: keyboardHeight) { _, _ in
                Task { @MainActor in
                    // 키보드 애니메이션/레이아웃 반영 타이밍 보정
                    try? await Task.sleep(nanoseconds: 80_000_000)
                    scrollToBottom(proxy: proxy, animated: true)
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(bottomAnchorId, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(bottomAnchorId, anchor: .bottom)
        }
    }

    private var composerBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about games…", text: $roomViewModel.composerText, axis: .vertical)
                .lineLimit(1...4)
                .disabled(roomViewModel.isSending)
                .focused($isComposerFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                }

            Button {
                Task { await roomViewModel.sendGuestMessage() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(playNowTint)
                    .clipShape(Circle())
            }
            .disabled(
                roomViewModel.isSending ||
                roomViewModel.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
            .accessibilityLabel("Send message")
        }
    }
}

private struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if message.author == .bot {
                bubble
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble
            }
        }
        .frame(maxWidth: .infinity, alignment: message.author == .bot ? .leading : .trailing)
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
        if message.author == .bot {
            return Color.white.opacity(0.12)
        }
        return Color.white.opacity(0.10)
    }

    private func linkTitle(for url: URL) -> String {
        if let host = url.host, host.isEmpty == false {
            return host
        }
        return url.absoluteString
    }
}

// MARK: - URL Segmenter (URL -> Link Button)

private enum LinkSegmentKind: Equatable {
    case text(String)
    case link(URL)
}

private struct LinkSegment: Identifiable, Equatable {
    let id = UUID()
    let kind: LinkSegmentKind
}

private enum LinkSegmenter {
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

// MARK: - Text Cleaning (출처 제거 + []() 찌꺼기 제거)

private enum TextCleaner {
    static func sanitizeMarkdownLinksAndSources(_ input: String) -> String {
        var output = input

        output = output.replacingOccurrences(
            of: #"\[[^\]]*\]\((https?://[^)\s]+)\)"#,
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

        output = output.replacingOccurrences(of: #"\[\s*\]"#, with: "", options: .regularExpression)
        output = output.replacingOccurrences(of: #"\(\s*\)"#, with: "", options: .regularExpression)
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

        output = removeOrphanPunctuationLines(output)
        return output
    }

    private static func removeOrphanPunctuationLines(_ input: String) -> String {
        var output = input

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

// MARK: - Typing Bubble (Animated Dots)

private struct TypingBubbleView: View {
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

// MARK: - Markdown Block Rendering (Headings + Bullets + Inline Markdown)

private struct MarkdownBlockView: View {
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

                case .bullet(let content):
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                            .font(.body.weight(.semibold))
                        Text(.init(content))
                            .font(.body)
                            .lineSpacing(3)
                    }

                case .text(let content):
                    Text(.init(content))
                        .font(.body)
                        .lineSpacing(3)
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
