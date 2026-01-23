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
    @StateObject var favoriteManager = FavoriteManager()

    @StateObject private var mainVM = GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.trendingNow)
    
    @StateObject private var trendingVM = GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.trendingNow)
    
    @StateObject private var ReleasesVM = GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.newReleases)

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor")
                    .ignoresSafeArea()
            VStack(spacing: 0) {
                    switch selectedTab {
                        case .home:
                            MainView(
                                viewModel: mainVM,
                                trendingVM: trendingVM,
                                newReleasesVM: ReleasesVM
                            )
                        case .discover:
                            SearchView(favoriteManager: favoriteManager)
                        case .library:
                            LibraryView()
                        case .profile:
                            MainView(
                                viewModel: mainVM,
                                trendingVM: trendingVM,
                                newReleasesVM: ReleasesVM
                            )
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
    }
}

#Preview {
    MainTabView()
}
