//
//  ResultHeader.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//
//  검색 결과 헤더 컴포넌트

import SwiftUI

// MARK: - Result Header

/// 검색/필터 결과 목록 상단에 표시되는 헤더 컴포넌트입니다.
///
/// - Responsibilities:
///     - 게임 컨트롤러 아이콘과 결과 타이틀 표시
///     - 결과 개수 표시
///
/// - Parameters:
///     - title: 헤더 타이틀 (예: "추천 게임", "PC · RPG 게임")
///     - count: 결과 개수
struct ResultHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: "gamecontroller.fill")
                .foregroundColor(.purple)

            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            Text("\(count)개")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            ResultHeader(title: "추천 게임", count: 42)
            Spacer()
        }
    }
}
