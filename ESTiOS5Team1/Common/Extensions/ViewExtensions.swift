//
//  ViewExtensions.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/7/26.
//

import SwiftUI

// MARK: - View Extensions

extension View {

    /// TextField에 커스텀 플레이스홀더를 적용하는 modifier입니다.
    ///
    /// SwiftUI의 기본 TextField placeholder는 스타일 커스터마이징이 제한적이므로,
    /// 이 modifier를 사용하여 색상, 폰트 등을 자유롭게 지정할 수 있습니다.
    ///
    /// - Parameters:
    ///   - shouldShow: 플레이스홀더 표시 여부 (일반적으로 텍스트가 비어있을 때 `true`)
    ///   - alignment: 플레이스홀더 정렬 (기본값: `.leading`)
    ///   - placeholder: 플레이스홀더로 표시할 View
    /// - Returns: 플레이스홀더가 적용된 View
    ///
    /// - Example:
    ///     ```swift
    ///     TextField("", text: $text)
    ///         .placeholder(when: text.isEmpty) {
    ///             Text("검색어를 입력하세요")
    ///                 .foregroundColor(.gray)
    ///         }
    ///     ```
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
