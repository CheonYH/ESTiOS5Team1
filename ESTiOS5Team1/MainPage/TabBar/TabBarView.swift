//
//  TabBarView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/14/26.
//

import SwiftUI

// MARK: - TabBarView

/// 앱 하단에 고정되는 커스텀 탭바 뷰입니다.
///
/// `TabbarButton`을 이용해 탭을 선택하고, 선택 상태는 `selectedTab` 바인딩으로 외부와 동기화됩니다.
struct TabBarView: View {

    /// 현재 선택된 탭(부모 뷰와 상태 공유)
    @Binding var selectedTab: Tab

    /// 탭바 높이(레이아웃 고정)
    private let height: CGFloat = 55

    var body: some View {
        VStack {
            // 필요 시 구분선 사용 가능
            // Divider()
            //     .frame(height: 1)
            //     .background(.white.opacity(0.2))

            HStack(spacing: 10) {
                TabbarButton(
                    icon: "house.fill",
                    iconName: "홈",
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
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, -15)
        }
        .frame(height: height)
        .background(Color.black.opacity(0.96))
    }
}
