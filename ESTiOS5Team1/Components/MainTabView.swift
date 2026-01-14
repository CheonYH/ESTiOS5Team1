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
                        //SearchView(favoriteManager: favoriteManager)
                        EmptyView()
                    case .library:
                        EmptyView()
                    case .profile:
                        EmptyView()
                }
            }
            
            TabBarView(selectedTab: $selectedTab)
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
    
}

#Preview {
    MainTabView()
}
