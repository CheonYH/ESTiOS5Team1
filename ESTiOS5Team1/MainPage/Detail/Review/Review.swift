//
//  Review.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/23/26.
//

import SwiftUI

struct Review: View {
    let onSubmit: (_ rating: Double, _ text: String) -> Void
    @State private var rating: Double = 4.5
    @State private var text: String = ""
    @FocusState private var focused: Bool
    var body: some View {
        VStack {
            Text("평가 남기기")
                .font(.headline)
                .foregroundStyle(.textPrimary)

            StarRatingView(rating: $rating)

            TextField("게임의 평가를 남겨주세요.", text: $text, axis: .vertical)
                .lineLimit(3...8)
                .focused($focused)
                .textFieldStyle(.plain)
                .padding()
                .foregroundStyle(.white)

            HStack {
                Spacer()
                Button {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

                    guard !trimmed.isEmpty else { return }
                    onSubmit(rating, trimmed)
                    text = ""
                    focused = false
                } label: {
                    Text("등록")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.purplePrimary, in: Capsule())
                }
            }
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white.opacity(0.06))
        )
    }
}

#Preview {
    Review { rating, text in
        print("submit:", rating, text)
    }
    .padding()
    .background(Color.white)
}
