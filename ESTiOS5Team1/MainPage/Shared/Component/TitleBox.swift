//
//  TitleBox.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//
import SwiftUI

struct TitleBox: View {
    var title: String
    var showsSeeAll: Bool = false
    let onSeeAllTap: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.textPrimary)

            Spacer()

            if showsSeeAll {
                Button("모두 보기") {
                    onSeeAllTap?()
                    // See All 버튼 이동
                    // trending now와 new Releases에서 사용하니 분류할 것
                }
                .font(.title3.bold())
                .foregroundStyle(.purplePrimary)
            }
        }
    }
}

struct ComponentFormat: View {

    var body: some View {

    }
}
