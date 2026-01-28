//
//  Review.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/23/26.
//

import SwiftUI

struct Review: View {
    let onSubmit: (_ rating: Int, _ text: String) -> Void
    @State private var rating: Int = 1
    @State private var content: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack {
            Text("평가 남기기")
                .font(.headline)
                .foregroundStyle(.textPrimary)

            StarRatingPicker(rating: $rating)

            TextField("", text: $content, prompt: Text("게임의 평가를 남겨주세요.").foregroundStyle(.white.opacity(0.4)), axis: .vertical)
                .lineLimit(3...8)
                .focused($focused)
                .padding(5)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 37/255, green: 37/255, blue: 57/255))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.gray.opacity(0.6), lineWidth: 1)
                )

            HStack {
                Spacer()
                Button {
                    let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

                    guard !trimmed.isEmpty else { return }
                    onSubmit(rating, trimmed)
                    content = ""
                    rating = 1
                    focused = false
                } label: {
                    Text("등록")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.vertical)
                        .padding(.horizontal, 25)
                        .background(.purplePrimary, in: RoundedRectangle(cornerRadius: 6))
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
