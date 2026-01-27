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
    
    @StateObject var favoriteManager = FavoriteManager()
    @StateObject private var tabBarState = TabBarState()
    @StateObject private var mainVM = GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.trendingNow)
    @StateObject private var trendingVM = GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.trendingNow)
    @StateObject private var releasesVM = GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.newReleases)
    
    private var isPageLoading: Bool {
        trendingVM.isLoading || releasesVM.isLoading
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
                                    }
                                )
                            }
                            .opacity(selectedTab == .home ? 1 : 0)
                            .allowsHitTesting(selectedTab == .home)
                        }
                        
                        if loadedTabs.contains(.discover) {
                            tabStack(isActive: selectedTab == .discover) {
                                SearchView(
                                    favoriteManager: favoriteManager,
                                    openSearchRequested: $openSearchRequested
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
                
                if isPageLoading {
                    loadingOverlay
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
            .environmentObject(favoriteManager)
            .environmentObject(tabBarState)
            .animation(.easeInOut(duration: 0.2), value: isPageLoading)
            .onChange(of: selectedTab) { loadedTabs.insert($0) }
    }
    private func tabStack<Content: View>(isActive: Bool, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            ZStack {
                Color("BGColor").ignoresSafeArea()
                content()
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: tabBarState.isHidden ? 0 : tabBarHeight)
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
