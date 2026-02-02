//
//  ErrorView.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//
//  공통 에러 컴포넌트 - 여러 화면에서 재사용 가능

import SwiftUI

// MARK: - Error View

/// 에러 발생 시 표시하는 공통 에러 뷰 컴포넌트입니다.
struct ErrorView: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("데이터를 불러올 수 없습니다")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: retry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("다시 시도")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.purple)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ErrorView(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "네트워크 연결을 확인해주세요."])) {
            print("Retry tapped")
        }
    }
}
