//
//  BottomTabBar.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//

import SwiftUI
import Combine

/// 앱의 최상위 탭 컨테이너입니다.
///
/// - 역할:
///   - 4개의 탭(Home/Discover/Library/Profile)을 `TabView` 대신 `NavigationStack` 기반으로 직접 스택팅하여
///     화면 전환 시 상태 유지/복원(지연 로딩 포함)을 관리합니다.
///   - 홈(트렌딩/릴리즈) 데이터 로딩 상태에 따라 전체 터치 차단 및 로딩 오버레이를 표시합니다.
///   - 리뷰 변경 알림(`.reviewDidChange`)을 수신하면 홈 관련 리스트들의 리뷰 통계를 갱신합니다.
///
/// - Note:
///   `loadedTabs`를 통해 탭을 최초 진입 시에만 생성하여, 불필요한 초기 네트워크/뷰 생성 비용을 줄입니다.
struct MainView: View {
    /// (사용 중/예정) 탭 아이콘 색상 상태 값입니다.
    @State var iconColor: Color = .gray
    /// 현재 선택된 탭입니다.
    @State private var selectedTab: Tab = .home
    /// 한 번이라도 진입해 생성된 탭 목록입니다.
    ///
    /// 탭 전환 시 기존 뷰를 유지해 스크롤/상태가 보존되도록 합니다.
    @State private var loadedTabs: Set<Tab> = [.home]
    /// 홈/프로필에서 검색 버튼을 눌렀을 때 Discover 탭의 검색창을 즉시 열도록 요청하는 플래그입니다.
    @State private var openSearchRequested = false
    /// 홈에서 장르를 눌렀을 때 Discover 탭으로 전달할 장르(선택 상태)입니다.
    @State private var pendingGenre: GameGenreModel?
    // [추가] 검색 상태 초기화용 (탭 전환 시 검색 비활성화)
    /// Discover 탭을 벗어날 때 검색 상태(텍스트/필터)를 초기화하도록 요청하는 플래그입니다.
    @State private var shouldResetSearch = false

    /// 즐겨찾기(라이브러리) 관리 객체입니다.
    ///
    /// 하위 뷰 전반에서 공유되므로 `EnvironmentObject`로 주입합니다.
    @StateObject var favoriteManager = FavoriteManager()

    /// 홈 메인 리스트용 ViewModel 입니다.
    @StateObject private var mainVM = GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.trendingNow)

    /// 트렌딩 섹션용 ViewModel 입니다.
    @StateObject private var trendingVM = GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.trendingNow)

    /// 신규 출시 섹션용 ViewModel 입니다.
    @StateObject private var releasesVM = GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.newReleases)

    /// 커스텀 탭바 표시/숨김 상태를 관리하는 EnvironmentObject 입니다.
    @StateObject private var tabBarState = TabBarState()

    /// 홈 화면의 주요 데이터가 로딩 중인지 여부입니다.
    ///
    /// - Note: 로딩 중에는 탭 전환/터치를 막아 화면이 어색하게 변하는 것을 방지합니다.
    private var isPageLoading: Bool {
        mainVM.isLoading || trendingVM.isLoading || releasesVM.isLoading
    }

    /// 홈에 필요한 데이터가 최소 1회 이상 로드되었는지 여부입니다.
    private var hasLoadedHome: Bool {
        mainVM.hasLoaded && trendingVM.hasLoaded && releasesVM.hasLoaded
    }

    var body: some View {
        ZStack {
            Color("BGColor")
                .ignoresSafeArea()
            VStack(spacing: 0) {
                ZStack {
                    if loadedTabs.contains(.home) {
                        tabStack(isActive: selectedTab == .home) {
                            HomeView(
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
        .onChange(of: selectedTab) { _, newTab in
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

    /// 각 탭을 `NavigationStack`으로 감싸 상태(네비게이션 경로)를 독립적으로 유지합니다.
    ///
    /// - Parameters:
    ///   - isActive: 현재 탭이 활성 상태인지 여부(히트테스트/투명도 제어용)
    ///   - content: 탭의 루트 컨텐츠
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

    /// 홈 데이터 로딩 중 화면 전체를 덮는 오버레이입니다.
    ///
    /// - Note: `zIndex`와 `allowsHitTesting`으로 사용자가 로딩 중에 조작하지 못하게 합니다.
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
    MainView()
}
