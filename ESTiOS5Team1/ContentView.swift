//
//  ContentView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import SwiftUI
import FirebaseCrashlytics

struct ContentView: View {

    var body: some View {
        Button("Crash Test") {
            Crashlytics.crashlytics().log("Test crash button tapped")
            fatalError("🔥 Crashlytics SwiftUI Test Crash")
        }
        .padding()
    }
}
