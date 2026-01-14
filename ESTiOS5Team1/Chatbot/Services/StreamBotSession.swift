//
//  StreamBotSession.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Combine
import Foundation
import StreamChat
import StreamChatSwiftUI

@MainActor
final class StreamBotSession: ObservableObject {
    enum State: Equatable {
        case idle
        case connecting
        case connected
        case failed(String)
    }

    @Published private(set) var state: State = .idle

    private(set) var streamChat: StreamChat?
    private(set) var chatClient: ChatClient?

    func connectBotIfPossible(credentials: BotStreamCredentials) async {
        guard !credentials.apiKey.isEmpty,
              !credentials.botUserIdentifier.isEmpty,
              !credentials.botUserToken.isEmpty
        else {
            state = .idle
            return
        }

        state = .connecting

        do {
            let tokenValue = try Token(rawValue: credentials.botUserToken)

            var clientConfig = ChatClientConfig(apiKey: .init(credentials.apiKey))
            clientConfig.isLocalStorageEnabled = true

            let createdClient = ChatClient(config: clientConfig)
            chatClient = createdClient
            streamChat = StreamChat(chatClient: createdClient)

            let userInfo = UserInfo(
                id: credentials.botUserIdentifier,
                name: credentials.botUserDisplayName.isEmpty ? credentials.botUserIdentifier : credentials.botUserDisplayName,
                imageURL: nil
            )

            try await createdClient.connectUser(userInfo: userInfo, token: tokenValue)
            state = .connected
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
