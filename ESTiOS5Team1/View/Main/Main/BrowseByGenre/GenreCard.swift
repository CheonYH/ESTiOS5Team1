//
//  GenreCardView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/8/26.
//
import SwiftUI
import Kingfisher
// MARK: - Genre Card

/// 장르 썸네일 카드 뷰입니다.
///
/// 배경 이미지(에셋) 위에 장르명 텍스트를 오버레이하여
/// 홈 화면의 장르 그리드에서 재사용합니다.

struct GenreCard: View {

    /// 표시할 장르 모델
    let genre: GameGenreModel

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(genre.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 220, height: 140)
                .clipped()
                .cornerRadius(Radius.cr16)

            VStack(alignment: .leading, spacing: 4) {
                Text(genre.displayName)
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))
            }
            .padding(10)
        }
    }
}
