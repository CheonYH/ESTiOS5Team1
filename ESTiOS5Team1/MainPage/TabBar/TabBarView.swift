//
//  TabBarView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/14/26.
//

import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: Tab

    var body: some View {
            VStack {
                Divider()
                    .frame(height: 1)
                    .background(.white.opacity(0.2))

                HStack(spacing: 10) {
                    TabbarButton(
                        icon: "house.fill",
                        iconName: "Home",
                        tab: .home,
                        selectedTab: $selectedTab
                    )

                    Spacer()

                    TabbarButton(
                        icon: "safari.fill",
                        iconName: "Discover",
                        tab: .discover,
                        selectedTab: $selectedTab
                    )

                    Spacer()

                    TabbarButton(
                        icon: "bookmark.fill",
                        iconName: "Library",
                        tab: .library,
                        selectedTab: $selectedTab
                    )

                    Spacer()

                    TabbarButton(
                        icon: "person.fill",
                        iconName: "Person",
                        tab: .profile,
                        selectedTab: $selectedTab
                    )
                }
                .padding()
            }
    }
}
