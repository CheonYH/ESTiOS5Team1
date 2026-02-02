//
//  CustomNavigationHeader.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/23/26.
//

import SwiftUI

// MARK: - Custom Navigation Header

/// NavigationStack 중첩 문제 해결을 위한 커스텀 네비게이션 헤더입니다.
struct CustomNavigationHeader: View {
    let title: String
    var showSearchButton: Bool = false
    var isSearchActive: Bool = false
    var onSearchTap: (() -> Void)?
    @Binding var showRoot: Bool

    var body: some View {
        ZStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }
        .overlay(alignment: .leading) {
            Button { showRoot = true } label: {
                Image("ChatImg4")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                    .font(.title3)
            }
        }
        .overlay(alignment: .trailing) {
            if showSearchButton {
                Button(action: { onSearchTap?() }) {
                    Image(systemName: isSearchActive ? "xmark" : "magnifyingglass")
                        .foregroundColor(.purple)
                        .font(.title3)
                }
//                .padding(.trailing, 16)
            }
        }
        .padding()
        .background(Color.black)
    }
}

// MARK: - Preview
// #Preview("CustomNavigationHeader") {
//    ZStack {
//        Color.black.ignoresSafeArea()
//
//        VStack {
//            CustomNavigationHeader(
//                title: "게임 탐색",
//                showSearchButton: true,
//                isSearchActive: false,
//                onSearchTap: { print("Search tapped") }
//            )
//
//            CustomNavigationHeader(
//                title: "내 게임",
//                showSearchButton: true,
//                isSearchActive: true,
//                onSearchTap: { print("Search tapped") }
//            )
//
//            Spacer()
//        }
//    }
// }
