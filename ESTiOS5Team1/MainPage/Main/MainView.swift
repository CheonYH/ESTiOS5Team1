//
//  MainView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/6/26.
//

import SwiftUI
import Kingfisher

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    // [수정] FavoriteManager 연동을 위해 추가
    @EnvironmentObject var favoriteManager: FavoriteManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor")
                    .ignoresSafeArea()

                VStack {
                    TopBarView()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 30) {
                            if let item = viewModel.featuredItem {
                                MainPoster(item: item)
                            } 
                            
                            TrendingNowGameView()
                            
                            BrowseByGenreGridView()
                            
                            NewReleasesView()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    MainView()
}
