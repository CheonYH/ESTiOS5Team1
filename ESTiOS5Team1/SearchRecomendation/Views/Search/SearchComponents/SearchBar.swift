//
//  SearchBar.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/7/26.
//

import SwiftUI

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("게임 포털, 태그 검색...", text: $searchText)
                .foregroundColor(.white)
                .placeholder(when: searchText.isEmpty) {
                    Text("게임 포털, 태그 검색...")
                        .foregroundColor(.gray)
                }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
