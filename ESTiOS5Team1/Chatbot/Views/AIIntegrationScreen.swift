//
//  AIIntegrationScreen.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import SwiftUI

struct AIIntegrationScreen: View {
    @Binding var settings: AppSettings
    @ObservedObject var botSession: StreamBotSession

    var body: some View {
        Form {
            Section("Stream Bot Connection") {
                statusRow

                TextField("API Key", text: $settings.botStream.apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Bot User ID", text: $settings.botStream.userId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Bot Name", text: $settings.botStream.userName)

                SecureField("Bot Token", text: $settings.botStream.userToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Default Channel CID", text: $settings.botStream.defaultChannelCid)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button("Save") { persistAndReload() }

                Button("Save & Connect Bot") {
                    persistAndReload()
                    Task { await botSession.connectBotIfPossible(credentials: settings.botStream) }
                }
            }

            Section("Alan") {
                Toggle("Enable Alan", isOn: $settings.alan.isEnabled)

                TextField("Endpoint", text: $settings.alan.endpoint)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Client Key (used as client_id)", text: $settings.alan.clientKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Toggle("Include Local Context", isOn: $settings.alan.includeLocalContext)

                Stepper(
                    "Context Messages: \(settings.alan.contextMessageCount)",
                    value: $settings.alan.contextMessageCount,
                    in: 0...30
                )

                Stepper(
                    "Max Context Chars: \(settings.alan.maxContextCharacters)",
                    value: $settings.alan.maxContextCharacters,
                    in: 500...6000,
                    step: 250
                )

                Button("Save Alan Settings") { persistAndReload() }
            }
        }
        .navigationTitle("AI / Keys")
        .onDisappear { settings.save() }
    }

    private func persistAndReload() {
        settings.save()
        settings = .load()
    }

    @ViewBuilder
    private var statusRow: some View {
        switch botSession.state {
        case .notConfigured:
            Label("Not configured", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
        case .connecting:
            Label("Connecting…", systemImage: "arrow.triangle.2.circlepath")
        case .connected:
            Label("Connected", systemImage: "checkmark.circle.fill")
        case .failed(let message):
            VStack(alignment: .leading, spacing: 6) {
                Label("Failed", systemImage: "xmark.octagon.fill")
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
