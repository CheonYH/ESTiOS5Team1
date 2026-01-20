//
//  ToastView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import SwiftUI

/// 단일 Toast UI를 렌더링하는 View입니다.
///
/// - Purpose:
///     FeedbackEvent의 정보를 사용하여
///     아이콘 + 텍스트 조합의 알림 UI를 표시합니다.
///
/// - Important:
///     iOS17 환경에서 `.background(Color.opacity)`가
///     material이나 overlay와 섞이면 무시되는 현상이 있어
///     Rectangle.fill(...) 로 강제 적용합니다.
///
struct ToastView: View {
    // MARK: - Properties

    /// 화면에 렌더링할 `FeedbackEvent`입니다.
    ///
    /// - Note:
    ///     상태(status)와 메시지(message)를 사용해 아이콘/배경/텍스트 스타일이 결정됩니다.
    let event: FeedbackEvent

    // MARK: - Body

    var body: some View {
        HStack(spacing: 10) {

            // 상태별 아이콘
            Image(systemName: iconName)
                .foregroundStyle(.white)
                .imageScale(.large)

            // 메시지 텍스트
            Text(event.message)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(backgroundColor)   // ← 핵심 변경점
        )
        .shadow(radius: 6)
        .padding(.horizontal, 20)
        .padding(.top, event.resolvedPlacement == .top ? 16 : 0)
        .padding(.bottom, event.resolvedPlacement == .bottom ? 20 : 0)
        .transition(
            .move(edge: event.resolvedPlacement == .top ? .top : .bottom)
            .combined(with: .opacity)
        )
    }
}

extension ToastView {
    // MARK: - Private Computed Properties

    /// 상태(status)에 따른 배경 색상
    private var backgroundColor: Color {
        switch event.status {
        case .success: Color.green.opacity(0.88)
        case .error: Color.red.opacity(0.88)
        case .warning: Color.yellow.opacity(0.88)
        case .info: Color.blue.opacity(0.88)
        }
    }

    /// 상태(status)에 따른 SF Symbol 아이콘
    private var iconName: String {
        switch event.status {
        case .success: "checkmark.circle.fill"
        case .error: "exclamationmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .info: "info.circle.fill"
        }
    }
}
