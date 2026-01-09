//
//  PlatformTestView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/9/26.
//

import SwiftUI

/// IGDB 플랫폼 목록을 조회해 나열하는 테스트용 View입니다.
///
/// - 테스트 목적:
///   - 플랫폼 데이터 조회 확인
///   - abbreviation 존재 여부 확인
///   - DTO → View 출력 흐름 검증
///
/// - Important:
///   이 화면은 정식 UI가 아니며, 데이터 검증 및 개발 진행을 위한 임시 구성입니다.
///   이후 정식 플랫폼 선택/필터 화면 또는 설정 화면으로 대체될 수 있습니다.
struct PlatformTestView: View {

    /// 플랫폼 목록 상태를 관리하는 ViewModel
    @StateObject private var viewModel = PlatformTestViewModel(service: IGDBServiceManager())

    var body: some View {
        List(viewModel.platforms) { platform in
            VStack(alignment: .leading, spacing: 4) {

                // 플랫폼 이름
                Text(platform.name)
                    .font(.headline)

                // Optional: 플랫폼 약칭 표시
                if let abbr = platform.abbreviation {
                    Text("Abbreviation: \(abbr)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Platforms")
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading…")
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

#Preview {
    NavigationStack {
        PlatformTestView()
    }
}
