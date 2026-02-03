//
//  SplashView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 2/3/26.
//


//
//  SplashView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import SwiftUI

/// 앱 시작 시 로딩 상태를 보여주는 스플래시 화면입니다.
struct SplashView: View {
    var body: some View {
        ProgressView("로그인 확인 중...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
}