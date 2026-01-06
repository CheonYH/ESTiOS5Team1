//
//  KingfisherTestView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import SwiftUI
import Kingfisher

struct KingfisherTestView: View {

    private let imageURL = URL(string: "https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?w=300")!
    var body: some View {
        VStack(spacing: 20) {

            Text("Kingfisher Test")
                .font(.title)
                .bold()

            KFImage(imageURL)
                .onFailure { error in
                        print("Kingfisher error:", error)
                }
                .placeholder {
                    ProgressView()
                }
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .cornerRadius(12)
                .shadow(radius: 4)

            Text("이미지가 보이면 Kingfisher 정상")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    KingfisherTestView()
}
