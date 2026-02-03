//
//  TitleBox.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//

import SwiftUI

// MARK: - TitleBox

/// 섹션 타이틀과 ‘모두 보기’ 버튼을 함께 제공하는 헤더 뷰입니다.
///
/// 리스트/그리드 섹션의 상단에 배치하여 제목을 보여주고,
/// 필요할 때만 ‘모두 보기’ 액션을 노출합니다.
struct TitleBox: View {

    /// 섹션 제목
    var title: String

    /// ‘모두 보기’ 버튼 표시 여부
    var showsSeeAll: Bool = false

    /// ‘모두 보기’ 버튼 탭 시 실행할 액션
    ///
    /// - Note:
    ///   `showsSeeAll == true`일 때만 호출됩니다.
    let onSeeAllTap: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.textPrimary)

            Spacer()

            if showsSeeAll {
                Button("모두 보기") {
                    onSeeAllTap?()
                }
                .font(.title3.bold())
                .foregroundStyle(.purplePrimary)
            }
        }
    }
}
