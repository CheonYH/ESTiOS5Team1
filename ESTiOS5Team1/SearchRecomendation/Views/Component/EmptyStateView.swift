//
//  EmptyStateView.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//
//  공통 빈 상태 컴포넌트 - 여러 화면에서 재사용 가능

import SwiftUI

// MARK: - Empty State View (통합)
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Preset Empty States
extension EmptyStateView {
    /// 검색 결과 없음
    static func noSearchResults(platform: PlatformFilterType, genre: GenreFilterType) -> EmptyStateView {
        let message: String
        if platform != .all && genre != .all {
            message = "\(platform.rawValue)에서 \(genre.displayName) 장르의 게임을 찾지 못했습니다.\n다른 조합을 시도해보세요."
        } else if platform != .all {
            message = "\(platform.rawValue) 플랫폼의 게임을 찾지 못했습니다."
        } else if genre != .all {
            message = "\(genre.displayName) 장르의 게임을 찾지 못했습니다."
        } else {
            message = "다른 검색어를 시도해보세요."
        }

        return EmptyStateView(
            icon: "magnifyingglass",
            title: "검색 결과가 없습니다",
            message: message
        )
    }

    /// 라이브러리 비어있음
    static var emptyLibrary: EmptyStateView {
        EmptyStateView(
            icon: "heart.slash",
            title: "저장된 게임이 없습니다",
            message: "게임 카드의 하트 아이콘을 눌러\n마음에 드는 게임을 저장하세요"
        )
    }

    /// 라이브러리 검색 결과 없음
    static var noLibrarySearchResults: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "검색 결과가 없습니다",
            message: "다른 검색어로 시도해보세요"
        )
    }
}

// MARK: - Preview
#Preview("Empty States") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            EmptyStateView.emptyLibrary
        }
    }
}
