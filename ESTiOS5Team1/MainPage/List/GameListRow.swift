//
//  GameListRow.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/20/26.
//
import SwiftUI
import Kingfisher

// MARK: - View

/// 세로 리스트에서 사용되는 게임 한 줄(Row) UI를 구성하는 뷰입니다.
///
/// 썸네일, 제목, 간단 정보 등을 한 행에 표시합니다.
struct GameListRow: View {
    let item: GameListItem

    var body: some View {
        HStack(spacing: 12) {
            // 썸네일
            if let coverURL = item.coverURL {
                KFImage(coverURL)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 113)))
                    .placeholder {
                        GameListCardPlaceholder()
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 110)
                    .clipped()
                    .cornerRadius(Radius.cr8)
            } else {
                GameListCardPlaceholder()
                    .frame(width: 90, height: 110)
                    .cornerRadius(Radius.cr8)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(item.genre.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.textPrimary.opacity(0.7))

                // 별점
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }
}
