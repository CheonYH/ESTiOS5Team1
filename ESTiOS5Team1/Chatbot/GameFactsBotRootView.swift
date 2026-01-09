//
//  GameFactsBotModel.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/9/26.
//

import SwiftUI

struct GameFactsBotRootView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        RootTabView()
            .environmentObject(appState)
            .task { await appState.configureStreamIfPossible() }
    }
}
