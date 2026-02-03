//
//  SwiftUIView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/8/26.
//

import SwiftUI

// MARK: - Browse By Genre Grid

/// 홈 화면에서 장르 목록을 가로 스크롤 2행 그리드로 보여주는 뷰입니다.
///
/// - Parameters:
///   - onGenreTap: 사용자가 특정 장르 카드를 탭했을 때 호출되는 콜백
///
/// - Note:
///     실제 네비게이션(예: SearchView로 이동)은 상위 뷰에서 처리하고,
///     이 뷰는 “어떤 장르가 눌렸는지”만 이벤트로 전달합니다.

struct BrowseByGenreGridView: View {
    /// 즐겨찾기(북마크) 상태를 공유하는 매니저
    ///
    /// 현재 파일에서는 직접 사용하지 않지만, 상위/하위 뷰에서 동일 매니저를 공유하기 위해 주입합니다.
    @EnvironmentObject var favoriteManager: FavoriteManager
    
    /// 장르 선택 이벤트 콜백
    let onGenreTap: (GameGenreModel) -> Void
    
    /// LazyHGrid 레이아웃을 위한 고정 높이 2행 구성
    private let rows = [
        GridItem(.fixed(140), spacing: 16),
        GridItem(.fixed(140), spacing: 16)
    ]
    var body: some View {
        VStack(alignment: .leading) {
            TitleBox(title: "장르", onSeeAllTap: nil)
            
            ScrollView(.horizontal, showsIndicators: false) {
                
                LazyHGrid(rows: rows, spacing: 15) {
                    ForEach(GameGenreModel.allCases) { genre in
                        Button {
                            onGenreTap(genre)
                        } label: {
                            GenreCard(genre: genre)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview {
    BrowseByGenreGridView(onGenreTap: { _ in})
        .environmentObject(FavoriteManager())
}
