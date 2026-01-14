//
//  AIIntegrationScreen.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import SwiftUI

struct AIIntegrationScreen: View {
    @Binding var settings: AppSettings
    let botSession: StreamBotSession

    var body: some View {
        NavigationStack {
            Form {
                Section("Bot Stream Login (only the bot logs in)") {
                    TextField("API Key", text: $settings.botStream.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Bot User Identifier", text: $settings.botStream.botUserIdentifier)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Bot Display Name", text: $settings.botStream.botUserDisplayName)

                    SecureField("Bot User Token", text: $settings.botStream.botUserToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button("Save & Connect Bot") {
                        settings.save()
                        Task { await botSession.connectBotIfPossible(credentials: settings.botStream) }
                    }

                    botStateView
                }

                Section("Alan API (Stage 2)") {
                    Toggle("Enable Alan", isOn: $settings.alan.isEnabled)
                    SecureField("Alan API Key", text: $settings.alan.apiKey)

                    TextField("Endpoint", text: $settings.alan.endpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    DisclosureGroup("Auth Header (only if required)") {
                        TextField("Header Field", text: $settings.alan.authHeaderField)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        TextField("Header Prefix", text: $settings.alan.authHeaderPrefix)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    Button("Save") { settings.save() }
                }

                Section("Storage") {
                    Text("Rooms and messages are saved locally (Application Support).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("AI / Keys")
        }
    }

    @ViewBuilder
    private var botStateView: some View {
        switch botSession.state {
        case .idle:
            Text("Bot is not connected.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .connecting:
            HStack {
                ProgressView()
                Text("Connecting…").font(.footnote)
            }
        case .connected:
            Text("Bot connected.").font(.footnote)
        case .failed(let message):
            Text("Failed: \(message)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
