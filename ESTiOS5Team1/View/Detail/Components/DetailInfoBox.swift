//
//  DetailInfoBox.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//

import SwiftUI
import Kingfisher

// MARK: - Detail Info Box

/// 게임 상세 화면 상단의 대표 정보를 표시하는 카드입니다.
///
/// 커버 이미지(또는 플레이스홀더)와 함께 타이틀/장르/플랫폼 아이콘,
/// 그리고 평점 관련 통계(유저 스코어/메타크리틱 등)를 한 번에 보여줍니다.
///
/// - Note:
///     커버 이미지는 Kingfisher의 `DownsamplingImageProcessor`를 사용해
///     지정한 크기로 디코딩하여 메모리 사용량을 줄입니다.

struct DetailInfoBox: View {
    /// 상세 화면에 표시할 게임 데이터 모델
    ///
    /// `GameDetailViewModel`에서 받아온 `GameDetailItem`을 주입받습니다.
    let item: GameDetailItem

    var body: some View {
        if let coverURL = item.coverURL {
            KFImage(coverURL)
                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 160, height: 93)))
                .placeholder {
                    GameListCardPlaceholder()
                }
                .resizable()
                .scaledToFit()
                .frame(height: 400)
                .clipped()
                .cornerRadius(Radius.card)

        } else {
            GameListCardPlaceholder()
                .frame(height: 400)
                .cornerRadius(Radius.card)
        }

        VStack(alignment: .leading) {

            VStack(alignment: .leading, spacing: 10) {
                Text(item.title)
                    .font(.title2.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(item.genre.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.pink.opacity(0.75))
                    .bold()
                    .padding(.horizontal, 5)
                    .background(.purple.opacity(0.2), in: Capsule())
                HStack {
                    ForEach(item.platforms, id: \.rawValue) { platform in
                        Image(systemName: platform.iconName)
                            .foregroundStyle(.textPrimary.opacity(0.6))
                            .font(.caption)
                    }
                }
            }
            .foregroundStyle(.textPrimary)
            .padding(.vertical, 5)

            Divider()
                .frame(height: 1)
                .background(.textPrimary.opacity(0.2))
            HStack {
                StatView(value: item.ratingText, title: "User Score", color: .mint)
                    .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)
                    .background(.textPrimary.opacity(0.2))

                StatView(value: item.metaScore, title: "Metacritic", color: .mint)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(.textPrimary.opacity(0.06))
        )

    }
}
