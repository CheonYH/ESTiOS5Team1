//
//  StreamBotSession.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation
import Combine

@MainActor
final class StreamBotSession: ObservableObject {
    enum State: Equatable {
        case notConfigured
        case connecting
        case connected
        case failed(String)
    }

    @Published private(set) var state: State = .notConfigured

    func connectBotIfPossible(credentials: BotStreamCredentials) async {
        guard !credentials.apiKey.isEmpty,
              !credentials.userId.isEmpty,
              !credentials.userToken.isEmpty
        else {
            state = .notConfigured
            return
        }

        state = .connecting
        state = .connected
    }
}
