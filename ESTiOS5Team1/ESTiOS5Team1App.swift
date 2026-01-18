//
//  ESTiOS5Team1App.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import SwiftUI
import SwiftData
import Firebase

@main
struct ESTiOS5Team1App: App {

    @StateObject private var toastManager: ToastManager
    @StateObject private var appViewModel: AppViewModel

    init() {
        let toast = ToastManager()
        _toastManager = StateObject(wrappedValue: toast)
        _appViewModel = StateObject(
            wrappedValue: AppViewModel(
                authService: AuthServiceImpl(),
                toast: toast
            )
        )

        FirebaseApp.configure()
    }

    @ViewBuilder
    var content: some View {
        switch appViewModel.state {
            case .launching:
                SplashView()

            case .signedOut:
                LoginView()

            case .signedIn:
                LogoutTestView()
        }
    }


    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()


    var body: some Scene {

        /*  WindowGroup {
         MainTabView()
         } */

        WindowGroup {
            content
                .environmentObject(appViewModel)
                .environmentObject(toastManager)
        }

        .modelContainer(sharedModelContainer)
    }

}
