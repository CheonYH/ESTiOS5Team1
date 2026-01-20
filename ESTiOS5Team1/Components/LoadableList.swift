//
//  LoadableList.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/16/26.
//

import SwiftUI

struct LoadableList<Items: RandomAccessCollection, Row: View, Destination: View>: View where Items.Element: Identifiable {
    let isLoading: Bool
    let error: Error?
    let items: Items

    var limit: Int?
    var loadingText: String = "로딩 중"

    let destination: (Items.Element) -> Destination
    let row: (Items.Element) -> Row

    var body: some View {
        if isLoading {
            ProgressView(loadingText)
        } else if let error {
            VStack {
                Text("오류발생")
                    .font(.headline)
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            let list = Array(items)
            ForEach(prefix(list)) { item in
                NavigationLink(destination: destination(item)) {
                    row(item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func prefix(_ array: [Items.Element]) -> [Items.Element] {
        guard let limit else { return array }
        return Array(array.prefix(limit))
    }
}
