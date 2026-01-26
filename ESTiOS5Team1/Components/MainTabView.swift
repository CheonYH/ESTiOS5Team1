//
//  BottomTabBar.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//

import SwiftUI

struct MainTabView: View {
    @State var iconColor: Color = .gray
    @State private var selectedTab: Tab = .home
    @State private var loadedTabs: Set<Tab> = [.home]
    @StateObject var favoriteManager = FavoriteManager()

    @StateObject private var mainVM = GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.trendingNow)

    @StateObject private var releasesVM = GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.newReleases)

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor")
                    .ignoresSafeArea()
            VStack(spacing: 0) {
                    ZStack {
                        if loadedTabs.contains(.home) {
                            MainView(
                                viewModel: mainVM,
                                trendingVM: mainVM,
                                newReleasesVM: releasesVM
                            )
                            .opacity(selectedTab == .home ? 1 : 0)
                            .allowsHitTesting(selectedTab == .home)
                        }

                        if loadedTabs.contains(.discover) {
                            SearchView(favoriteManager: favoriteManager)
                                .opacity(selectedTab == .discover ? 1 : 0)
                                .allowsHitTesting(selectedTab == .discover)
                        }

                        if loadedTabs.contains(.library) {
                            LibraryView()
                                .opacity(selectedTab == .library ? 1 : 0)
                                .allowsHitTesting(selectedTab == .library)
                        }

                        if loadedTabs.contains(.profile) {
                            MainView(
                                viewModel: mainVM,
                                trendingVM: mainVM,
                                newReleasesVM: releasesVM
                            )
                            .opacity(selectedTab == .profile ? 1 : 0)
                            .allowsHitTesting(selectedTab == .profile)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    TabBarView(selectedTab: $selectedTab)
                }
            }
            .environmentObject(favoriteManager)
        }
        .onChange(of: selectedTab) { tab in
            loadedTabs.insert(tab)
        }
    }
}

#Preview {
    MainTabView()
}
