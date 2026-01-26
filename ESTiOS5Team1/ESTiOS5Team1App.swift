//
//  ESTiOS5Team1App.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import SwiftUI
import SwiftData
import Firebase
import GoogleSignIn
import FirebaseAnalytics

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
    }

    @ViewBuilder
    var content: some View {
        switch appViewModel.state {
            case .launching:
                SplashView()

            case .signedOut:
                LoginView()

            case .signedIn:
                MainTabView()

            case .socialNeedsRegister:
                NicknameCreateView(prefilledEmail: appViewModel.prefilledEmail)
        }
    }

    // SwiftData 컨테이너 (struct 내부 유지)
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
        WindowGroup {
             ZStack {
                 content
             }
             .frame(maxWidth: .infinity, maxHeight: .infinity)
             .environmentObject(toastManager)
             .environmentObject(appViewModel)
             .onOpenURL { url in
                 GIDSignIn.sharedInstance.handle(url)
             }
             .overlay(alignment: toastManager.placement == .top ? .top : .bottom) {
                 if let event = toastManager.event {
                     ToastView(event: event)
                         .transition(.move(edge: toastManager.placement == .top ? .top : .bottom).combined(with: .opacity))
                         .padding()
                 }
             }

            // DetailInfoTestView()
        }
        .modelContainer(sharedModelContainer)
    }
}
