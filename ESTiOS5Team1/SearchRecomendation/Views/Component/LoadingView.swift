//
//  LoadingView.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//
//  공통 로딩 컴포넌트 - 여러 화면에서 재사용 가능

import SwiftUI

// MARK: - Loading View
struct LoadingView: View {
    var message: String = "게임 정보를 불러오는 중..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.purple)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        LoadingView()
    }
}
