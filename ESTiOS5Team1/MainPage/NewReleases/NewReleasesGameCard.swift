//
//  SwiftUIView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/9/26.
//

import SwiftUI
import Kingfisher

struct NewReleasesGameCard: View {
    let item: GameListItem

    var body: some View {
            HStack {
                KFImage(item.coverURL)
                    .placeholder {
                        ProgressView()
                    }
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(8)

                VStack(alignment: .leading) {
                    Text(item.title)

                    Text(item.genre.joined(separator: " · "))
                        .font(.caption)

                    HStack {
                        RatingText(item: item)

                        Text("플랫폼 아이콘")

                        Spacer()

                        Button {
                            // 추가 버튼
                        } label: {
                            Image(systemName: "plus")
                                .padding(10)
                                .background(.purple, in: RoundedRectangle(cornerRadius: 8))
                        }

                    }
                }
                .foregroundStyle(.white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.06))
            )
        }
}
