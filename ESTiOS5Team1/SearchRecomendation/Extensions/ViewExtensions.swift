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
