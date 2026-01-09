//
//  GameFactsBotScreens.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/9/26.
//

import Combine
import StreamChat
import StreamChatSwiftUI
import SwiftUI
import UIKit

// MARK: - Tabs

struct RootTabView: View {
    var body: some View {
        TabView {
            ChatbotScreen()
                .tabItem { Label("Chat", systemImage: "message") }

            ThemeScreen()
                .tabItem { Label("Theme", systemImage: "paintpalette") }

            AIIntegrationScreen()
                .tabItem { Label("AI/Keys", systemImage: "gearshape") }
        }
    }
}

// MARK: - Stream ViewFactory (required conformance)

final class GameBotViewFactory: ViewFactory {
    @Injected(\.chatClient) var chatClient: ChatClient

    static let shared = GameBotViewFactory()
    private init() {}
}

// MARK: - Chat Screen

struct ChatbotScreen: View {
    @EnvironmentObject private var appState: AppState
    @Injected(\.chatClient) private var chatClient: ChatClient

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("GameFactsBot")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Sample Reply") { sendSampleBotReply() }
                            .disabled(appState.connectionState != .connected)
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch appState.connectionState {
        case .connected:
            ChatChannelView(
                viewFactory: GameBotViewFactory.shared,
                channelController: chatClient.channelController(
                    for: resolvedChannelId,
                    messageOrdering: .topToBottom
                )
            )

        case .notConfigured:
            ConfigurationHintView()

        case .connecting:
            ProgressView("Connecting…")

        case .failed(let errorMessage):
            VStack(spacing: 12) {
                Text("Connection failed").font(.headline)
                Text(errorMessage).font(.footnote)
                Button("Retry") { Task { await appState.configureStreamIfPossible() } }
            }
            .padding()
        }
    }

    private var resolvedChannelId: ChannelId {
        let channelCidString = appState.settings.stream.channelCID
        if let channelId = try? ChannelId(cid: channelCidString) {
            return channelId
        }
        return ChannelId(type: .messaging, id: "game-facts-bot")
    }

    private func sendSampleBotReply() {
        let channelController = chatClient.channelController(for: resolvedChannelId)

        let sampleMessageText = """
        ✅ Example (Stage 1 dummy reply)
        - Similar games: (placeholder)
        - Build tips: (placeholder)
        Sources:
        - https://www.igdb.com/ (example)
        - https://example.com/guide (example)
        """

        channelController.createNewMessage(text: sampleMessageText) { _ in }
    }
}

private struct ConfigurationHintView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Stream Chat not configured").font(.headline)
            Text("Go to AI/Keys → add Stream API Key, User ID, Token, and Channel CID.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Theme Screen

struct ThemeScreen: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Core") {
                colorPicker("Background", $appState.settings.theme.background)
                colorPicker("Tint", $appState.settings.theme.tint)
            }

            Section("Bubbles") {
                colorPicker("My Bubble", $appState.settings.theme.currentUserBubble)
                colorPicker("Other Bubble", $appState.settings.theme.otherUserBubble)
            }

            Section("Text") {
                colorPicker("My Text", $appState.settings.theme.currentUserText)
                colorPicker("Other Text", $appState.settings.theme.otherUserText)
            }

            Button("Apply Theme") {
                appState.saveSettings()
            }
        }
        .navigationTitle("Theme")
    }

    private func colorPicker(_ title: String, _ rgbaBinding: Binding<RGBAColor>) -> some View {
        ColorPicker(
            title,
            selection: Binding(
                get: { rgbaBinding.wrappedValue.swiftUIColor },
                set: { newColor in
                    let uiColorValue = UIColor(newColor)

                    var redComponent: CGFloat = 0
                    var greenComponent: CGFloat = 0
                    var blueComponent: CGFloat = 0
                    var alphaComponent: CGFloat = 0

                    uiColorValue.getRed(
                        &redComponent,
                        green: &greenComponent,
                        blue: &blueComponent,
                        alpha: &alphaComponent
                    )

                    rgbaBinding.wrappedValue = RGBAColor(
                        redComponent: redComponent,
                        greenComponent: greenComponent,
                        blueComponent: blueComponent,
                        alphaComponent: alphaComponent
                    )
                }
            )
        )
    }
}

// MARK: - AI / Keys Screen

struct AIIntegrationScreen: View {
    @EnvironmentObject private var appState: AppState

    private var isConnecting: Bool {
        appState.connectionState == .connecting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection Status") {
                    connectionStatusRow
                }

                Section("Stream Chat (required for Stage 1 chat UI)") {
                    TextField("API Key", text: $appState.settings.stream.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("User ID", text: $appState.settings.stream.userId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("User Name", text: $appState.settings.stream.userName)

                    SecureField("User Token", text: $appState.settings.stream.userToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Channel CID (e.g. messaging:game-facts-bot)", text: $appState.settings.stream.channelCID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button {
                        Task { appState.saveSettings() }
                    } label: {
                        HStack {
                            Text("Save & Connect")
                            if isConnecting {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isConnecting)
                }

                Section("Alan (Stage 2 placeholder)") {
                    Toggle("Enable Alan", isOn: $appState.settings.alan.isEnabled)
                    TextField("Project ID", text: $appState.settings.alan.projectId)
                    SecureField("Alan API Key", text: $appState.settings.alan.apiKey)
                    TextField("Endpoint", text: $appState.settings.alan.endpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Text("Alan API is not integrated in Stage 1.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Prompt Injection (Stage 3 tuning)") {
                    TextEditor(text: $appState.settings.prompts.systemPrompt)
                        .frame(minHeight: 160)

                    TextEditor(text: $appState.settings.prompts.injectionNotes)
                        .frame(minHeight: 120)

                    HStack {
                        Button("Load Example") {
                            appState.settings.prompts.systemPrompt = PromptExamples.gameFactsSystemPrompt
                            appState.settings.prompts.injectionNotes = PromptExamples.injectionNotes
                        }
                        Spacer()
                        Button("Save") { appState.saveSettings() }
                            .disabled(isConnecting)
                    }
                }
            }
            .navigationTitle("AI / Keys")
        }
    }

    @ViewBuilder
    private var connectionStatusRow: some View {
        switch appState.connectionState {
        case .notConfigured:
            Label("Not configured", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
        case .connecting:
            Label("Connecting…", systemImage: "arrow.triangle.2.circlepath")
        case .connected:
            Label("Connected", systemImage: "checkmark.circle.fill")
        case .failed(let errorMessage):
            VStack(alignment: .leading, spacing: 6) {
                Label("Failed", systemImage: "xmark.octagon.fill")
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Stream-backed Preview Support

@MainActor
final class StreamChatPreviewEnvironment: Combine.ObservableObject {
    @Published var isReady = false
    @Published var errorMessage: String?

    let chatClient: ChatClient
    let streamChat: StreamChat
    private(set) var channelController: ChatChannelController?

    init(theme: ChatbotTheme) {
        var config = ChatClientConfig(apiKey: .init("8br4watad788"))
        config.isLocalStorageEnabled = true

        let client = ChatClient(config: config)
        chatClient = client

        let appearance = Appearance(colors: theme.makeStreamColors())
        streamChat = StreamChat(chatClient: client, appearance: appearance)

        Task { await bootstrap() }
    }

    private func bootstrap() async {
        do {
            let tokenValue = try Token(
                rawValue: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.kFSLHRB5X62t0Zlc7nwczWUfsQMwfkpylC6jCUZ6Mc0"
            )

            let imageUrlString = "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg"
            let imageUrl = URL(string: imageUrlString)

            let userInfo = UserInfo(
                id: "luke_skywalker",
                name: "Luke Skywalker",
                imageURL: imageUrl
            )

            try await chatClient.connectUser(userInfo: userInfo, token: tokenValue)

            let channelId = ChannelId(type: .messaging, id: "gamefacts-preview")
            let controller = try chatClient.channelController(
                createChannelWithId: channelId,
                name: "GameFactsBot Preview",
                members: ["luke_skywalker", "han_solo"],
                isCurrentUserMember: true,
                messageOrdering: .topToBottom
            )

            channelController = controller
            try await controller.synchronize()

            controller.createNewMessage(text: "👋 Preview is live (Stream-backed).") { _ in }
            isReady = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("Chatbot (Stream-backed)") {
    StreamChatPreviewHost()
}

private struct StreamChatPreviewHost: View {
    @StateObject private var appState: AppState
    @StateObject private var previewEnvironment: StreamChatPreviewEnvironment

    init() {
        let theme = ChatbotTheme.default

        let configuredAppState = AppState()
        configuredAppState.settings.theme = theme

        _appState = StateObject(wrappedValue: configuredAppState)
        _previewEnvironment = StateObject(wrappedValue: StreamChatPreviewEnvironment(theme: theme))
    }

    var body: some View {
        NavigationStack {
            if let errorMessage = previewEnvironment.errorMessage {
                Text("Preview error: \(errorMessage)")
                    .padding()
            } else if previewEnvironment.isReady, let channelController = previewEnvironment.channelController {
                ChatChannelView(
                    viewFactory: GameBotViewFactory.shared,
                    channelController: channelController
                )
            } else {
                ProgressView("Connecting Stream…")
            }
        }
        .environmentObject(appState)
    }
}
