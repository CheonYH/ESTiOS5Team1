//
//  TitleBox.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//
import SwiftUI

struct TitleBox: View {

    var title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.white)

            Spacer()

            Button {
                // See All 버튼 이동
                // trending now와 new Releases에서 사용하니 분류할 것
            } label: {
                Text("See All")
                    .font(.title3.bold())
            }
        }
    }
}

struct ComponentFormat: View {
    
    var body: some View {
        
    }
}
