//
//  ContentView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import SwiftUI
import Firebase

struct ContentView: View {

    var body: some View {
        Button("Crash Test") {
            Crashlytics.crashlytics().log("SPM으로 설치후 두번째 테스트 중입니다.")
            fatalError("🔥 Crashlytics SwiftUI Test Crash")
        }
        .padding()
    }
}
