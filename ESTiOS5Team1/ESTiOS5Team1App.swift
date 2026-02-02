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
import FirebaseCrashlytics

@main
struct ESTiOS5Team1App: App {

    @StateObject private var toastManager: ToastManager
    @StateObject private var appViewModel: AppViewModel
    @StateObject private var authViewModel: AuthViewModel

    init() {
        let toast = ToastManager()
        let authVM = AuthViewModel(service: AuthServiceImpl())
        _toastManager = StateObject(wrappedValue: toast)
        _authViewModel = StateObject(wrappedValue: authVM)
        _appViewModel = StateObject(
            wrappedValue: AppViewModel(
                authService: AuthServiceImpl(),
                toast: toast
            )
        )
    }

    @ViewBuilder
    var content: some View {
        if !appViewModel.isInitialized {
            SplashView()
        } else {
            switch appViewModel.state {
                case .launching:
                    SplashView()

                case .signedOut:
                    LoginView()

                case .signedIn:
                    // 서버에서 내려준 온보딩 완료 여부 기준으로 분기
                    if appViewModel.onboardingCompleted {
                        MainTabView()
                    } else {
                        OnboardingView(
                            isOnboardingComplete: Binding(
                                get: { appViewModel.onboardingCompleted },
                                set: { appViewModel.onboardingCompleted = $0 }
                            )
                        )
                    }

                case .socialNeedsRegister:
                    NicknameCreateView(prefilledEmail: appViewModel.prefilledEmail)
            }
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
            Crashlytics.crashlytics().record(error: error)
            Crashlytics.crashlytics().log("ModelContainer 생성 실패. in-memory 컨테이너로 fallback")
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [fallback]))
                ?? (try! ModelContainer(for: schema, configurations: [fallback]))
        }
    }()

    var body: some Scene {
        WindowGroup {
             ZStack {
                 Color.BG
                     .ignoresSafeArea()
                     .ignoresSafeArea(.keyboard)
                 content
                // MainTabView()

             }
             .frame(maxWidth: .infinity, maxHeight: .infinity)
             .environmentObject(toastManager)
             .environmentObject(appViewModel)
             .environmentObject(authViewModel)
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
