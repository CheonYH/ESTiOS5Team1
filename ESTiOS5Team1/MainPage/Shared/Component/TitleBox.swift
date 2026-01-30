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
                }
                .font(.title3.bold())
                .foregroundStyle(.purplePrimary)
            }
        }
    }
}
