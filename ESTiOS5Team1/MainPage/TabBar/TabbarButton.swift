//
//  TabbarButton.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//

import SwiftUI
enum Tab {
    case home, discover, library, profile
}
struct TabbarButton: View {
    let icon: String
    let iconName: String
    let tab: Tab
    @Binding var selectedTab: Tab

    var isSelected: Bool { selectedTab == tab }
    var body: some View {
        Button {
            withAnimation(.easeInOut) {
                selectedTab = tab
            }

        } label: {
            VStack {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)

                Text(iconName)
            }
            .foregroundStyle(isSelected ? .purple : .gray)
        }
    }
}
