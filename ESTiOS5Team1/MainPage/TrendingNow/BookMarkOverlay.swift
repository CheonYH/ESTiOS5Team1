//
//  BookMarkOverlay.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//

import SwiftUI

struct BookMarkOverlay: View {
    let item: GameListItem
    @State var isBookMark: Bool = false

    var body: some View {
        HStack {
            RatingText(item: item)

            Spacer()

            // 여기 버튼 터치가 막혀있음 원인을 찾을 것
            Button {
                print("북마크 완료!")
                isBookMark = !isBookMark
            } label: {
                Image(systemName: isBookMark ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(.symbolPrimary)
                    .padding(10)
                    .background(.black.opacity(0.8), in: Circle())
            }
        }
        .padding(4)
    }
}

