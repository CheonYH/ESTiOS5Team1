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

    @StateObject private var appViewModel = AppViewModel(authService: AuthServiceImpl())
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

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {

      /*  WindowGroup {
            MainTabView()
        } */

        WindowGroup {
            switch appViewModel.state {
                case .launching:
                    SplashView()
                case .signedOut:
                    LoginView()
                        .environmentObject(appViewModel)
                case .signedIn:
                    LogoutTestView()
                        .environmentObject(appViewModel)
            }
        } 
        .modelContainer(sharedModelContainer)
    }

}
