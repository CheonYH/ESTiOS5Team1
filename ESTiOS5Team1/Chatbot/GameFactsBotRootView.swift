import SwiftUI

struct GameFactsBotRootView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        RootTabView()
            .environmentObject(appState)
            .task { await appState.configureStreamIfPossible() }
    }
}