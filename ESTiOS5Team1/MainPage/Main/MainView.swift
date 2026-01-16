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
    @State private var isSearchActive = false  // 추가
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor")
                    .ignoresSafeArea()
                
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        // 메뉴 액션
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Image(systemName: "book")
                            .foregroundStyle(.purple)
                        Text("GameVault")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // 검색 액션
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 0.5)
            }
        }
    }
}

#Preview {
    MainView()
}
