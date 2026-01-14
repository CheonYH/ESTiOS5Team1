//
//  SplashView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ProgressView("로그인 확인 중...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
}
