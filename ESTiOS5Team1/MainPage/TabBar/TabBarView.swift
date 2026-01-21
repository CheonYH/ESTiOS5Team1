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
                        iconName: "메인",
                        tab: .home,
                        selectedTab: $selectedTab
                    )
                    .frame(maxWidth: .infinity)

                    Spacer()

                    TabbarButton(
                        icon: "safari.fill",
                        iconName: "게임 찾기",
                        tab: .discover,
                        selectedTab: $selectedTab
                    )
                    .frame(maxWidth: .infinity)
                    
                    Spacer()

                    TabbarButton(
                        icon: "heart.fill",
                        iconName: "내 게임",
                        tab: .library,
                        selectedTab: $selectedTab
                    )
                    .frame(maxWidth: .infinity)
                    
                    Spacer()

                    TabbarButton(
                        icon: "person.fill",
                        iconName: "프로필",
                        tab: .profile,
                        selectedTab: $selectedTab
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .contentShape(Rectangle())
            }
    }
}
