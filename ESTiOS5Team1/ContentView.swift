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
            Crashlytics.crashlytics().log("Crashlytics 테스트 로그")
            let error = NSError(
                domain: "CrashlyticsTest",
                code: 9999,
                userInfo: [NSLocalizedDescriptionKey: "수동 Crashlytics 테스트 에러"]
            )
            Crashlytics.crashlytics().record(error: error)
        }
        .padding()
    }
}
