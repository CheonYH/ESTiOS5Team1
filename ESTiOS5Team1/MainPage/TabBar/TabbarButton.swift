//
//  TabbarButton.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//

import SwiftUI

// MARK: - Tab

/// 앱의 하단 탭 종류를 정의합니다.
///
/// 탭 선택 상태는 `TabBarView`/`TabbarButton`에서 이 타입을 기준으로 비교합니다.
enum Tab {
    /// 홈 탭
    case home
    /// 탐색/디스커버 탭
    case discover
    /// 내 게임(라이브러리) 탭
    case library
    /// 프로필 탭
    case profile
}

// MARK: - TabbarButton

/// 탭바에서 개별 탭을 표현하는 버튼 뷰입니다.
///
/// 아이콘 + 텍스트를 세로로 배치하고, 현재 선택된 탭이면 강조 색상으로 표시합니다.
struct TabbarButton: View {
    
    /// SF Symbols 이름(예: `house.fill`)
    let icon: String
    
    /// 탭 라벨 텍스트(예: “홈”, “프로필”)
    let iconName: String
    
    /// 이 버튼이 담당하는 탭 값
    let tab: Tab
    
    /// 현재 선택된 탭(부모 뷰와 상태 공유)
    @Binding var selectedTab: Tab
    
    /// 현재 버튼이 선택 상태인지 여부
    var isSelected: Bool { selectedTab == tab }
    
    var body: some View {
        Button {
            selectedTab = tab
        } label: {
            VStack {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 14)
                
                Text(iconName)
            }
            .foregroundStyle(isSelected ? .purple : .gray)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}
