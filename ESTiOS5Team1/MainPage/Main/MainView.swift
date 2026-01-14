//
//  MainView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/6/26.
//

import SwiftUI
import Kingfisher

struct MainView: View {
    @State var imageColor: Color = .white
    @State var textColor: Color = .white
    
    @StateObject private var viewModel = MainViewModel()
// 패딩 잘못 주고있음
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack {
                    TopBarView()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 30) {
                            if let item = viewModel.featuredItem {
                                MainPoster(imageColor: .white, textColor: .white, item: item)
                            }
                            
                            TrendingNowGameView()
                            
                            BrowseByGenreGridView()
                            
                            TitleBox(title: "New Releases")
                            
                            NewReleasesView()
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    MainView()
    .background(Color.black)
}
