//
//  BottomTabBar.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//

import SwiftUI

struct MainTabView: View {
    @State var isClick: Bool = false
    @State var iconColor: Color = .gray
    @State private var selectedTab: Tab = .home
    @StateObject var favoriteManager = FavoriteManager()
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                    case .home:
                        MainView()
                    case .discover:
                        // [수정] SearchView와 내부 GameGridView에서 @EnvironmentObject로 FavoriteManager를 사용
                        // .environmentObject()로 주입하지 않으면 런타임 크래시 발생
                        SearchView(favoriteManager: favoriteManager)
                            .environmentObject(favoriteManager)
                    case .library:
                        // [수정] LibraryView 연결 - @EnvironmentObject로 FavoriteManager 주입
                        LibraryView()
                            .environmentObject(favoriteManager)
                    case .profile:
                        MainView()
                }
            }
            
            TabBarView(selectedTab: $selectedTab)
        }
        .environmentObject(favoriteManager)
        .background(Color.black)
        .ignoresSafeArea()
    }
}

#Preview {
    MainTabView()
}
