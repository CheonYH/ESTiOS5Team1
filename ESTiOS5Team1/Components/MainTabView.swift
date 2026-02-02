//
//  BottomTabBar.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//

import SwiftUI
import Combine

struct MainTabView: View {
    @State var iconColor: Color = .gray
    @State private var selectedTab: Tab = .home
    @State private var loadedTabs: Set<Tab> = [.home]
    @State private var openSearchRequested = false
    @State private var pendingGenre: GameGenreModel?
    // [추가] 검색 상태 초기화용 (탭 전환 시 검색 비활성화)
    @State private var shouldResetSearch = false

    @StateObject var favoriteManager = FavoriteManager()

    @StateObject private var mainVM = GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.trendingNow)

    @StateObject private var trendingVM = GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.trendingNow)

    @StateObject private var releasesVM = GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.newReleases)

    @StateObject private var tabBarState = TabBarState()

    private var isPageLoading: Bool {
        mainVM.isLoading || trendingVM.isLoading || releasesVM.isLoading
    }

    private var hasLoadedHome: Bool {
        mainVM.hasLoaded && trendingVM.hasLoaded && releasesVM.hasLoaded
    }

    private let tabBarHeight: CGFloat = 86

    var body: some View {
            ZStack {
                Color("BGColor")
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    ZStack {
                        if loadedTabs.contains(.home) {
                            tabStack(isActive: selectedTab == .home) {
                                MainView(
                                    viewModel: mainVM,
                                    trendingVM: trendingVM,
                                    newReleasesVM: releasesVM,
                                    onSearchTap: {
                                        openSearchRequested = true
                                        selectedTab = .discover
                                        loadedTabs.insert(.discover)
                                    },
                                    onGenreTap: { genre in
                                        pendingGenre = genre
                                        selectedTab = .discover
                                        loadedTabs.insert(.discover)
                                    }
                                )
                            }
                            .opacity((selectedTab == .home && hasLoadedHome && !isPageLoading) ? 1 : 0)
                            .allowsHitTesting(selectedTab == .home)
                        }

                        if loadedTabs.contains(.discover) {
                            tabStack(isActive: selectedTab == .discover) {
                                SearchView(
                                    favoriteManager: favoriteManager,
                                    openSearchRequested: $openSearchRequested,
                                    pendingGenre: $pendingGenre,
                                    shouldResetSearch: $shouldResetSearch
                                )
                                    .opacity(selectedTab == .discover ? 1 : 0)
                                    .allowsHitTesting(selectedTab == .discover)
                            }
                        }

                        if loadedTabs.contains(.library) {
                            tabStack(isActive: selectedTab == .library) {
                                LibraryView()
                                    .opacity(selectedTab == .library ? 1 : 0)
                                    .allowsHitTesting(selectedTab == .library)
                            }
                        }

                        if loadedTabs.contains(.profile) {
                            tabStack(isActive: selectedTab == .profile) {
                                ProfileView(
                                    onSearchTap: {
                                        openSearchRequested = true
                                        selectedTab = .discover
                                        loadedTabs.insert(.discover)
                                    }
                                )
                                    .opacity(selectedTab == .profile ? 1 : 0)
                                    .allowsHitTesting(selectedTab == .profile)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if !tabBarState.isHidden {
                        TabBarView(selectedTab: $selectedTab)
                    }
                }
                .allowsHitTesting(!isPageLoading)

                if !hasLoadedHome || isPageLoading {
                    loadingOverlay
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
            .environmentObject(favoriteManager)
            .environmentObject(tabBarState)
            .animation(.easeInOut(duration: 0.2), value: isPageLoading)
            .onChange(of: selectedTab) { newTab in
                loadedTabs.insert(newTab)
                // [추가] discover 탭에서 다른 탭으로 이동 시 검색 상태 초기화
                if newTab != .discover {
                    shouldResetSearch = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .reviewDidChange)) { notification in
                guard let gameId = notification.userInfo?["gameId"] as? Int else { return }

                Task {
                    await mainVM.refreshReviewStats(for: gameId)
                    await trendingVM.refreshReviewStats(for: gameId)
                    await releasesVM.refreshReviewStats(for: gameId)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
    }

    private func tabStack<Content: View>(isActive: Bool, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            ZStack {
                Color("BGColor").ignoresSafeArea()
                content()
            }
        }
        .opacity(isActive ? 1 : 0)
        .allowsHitTesting(isActive)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color("BGColor")
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(2.2)
                    .padding()

                Text("불러오는 중…")
                    .font(.caption)
                    .foregroundStyle(.textPrimary.opacity(0.7))
            }
        }
    }

}

#Preview {
    MainTabView()
}
