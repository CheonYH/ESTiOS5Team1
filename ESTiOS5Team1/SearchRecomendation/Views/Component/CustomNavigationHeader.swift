//
//  CustomNavigationHeader.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/23/26.
//

import SwiftUI

// MARK: - Custom Navigation Header
/// NavigationStack 중첩 문제 해결을 위한 커스텀 헤더
/// 여러 화면에서 재사용 가능
struct CustomNavigationHeader: View {
    let title: String
    var showSearchButton: Bool = false
    var isSearchActive: Bool = false
    var onSearchTap: (() -> Void)? = nil
    @Binding var showRoot: Bool
    
    var body: some View {
        HStack {
            Button { showRoot = true } label: {
                Image(systemName: "book")
                    
            }
            
            Spacer()

            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()
        }
        .overlay(alignment: .trailing) {
            if showSearchButton {
                Button(action: { onSearchTap?() }) {
                    Image(systemName: isSearchActive ? "xmark" : "magnifyingglass")
                        .foregroundColor(.white)
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
//#Preview("CustomNavigationHeader") {
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
//}
