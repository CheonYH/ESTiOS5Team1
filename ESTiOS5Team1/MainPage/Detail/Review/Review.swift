//
//  Review.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/23/26.
//

import SwiftUI

struct Review: View {
    let onSubmit: (_ rating: Int, _ text: String) -> Void
    let submitTitle: String
    @State private var rating: Int
    @State private var content: String
    @FocusState private var focused: Bool

    init(
        initialRating: Int = 1,
        initialContent: String = "",
        submitTitle: String = "등록",
        onSubmit: @escaping (_ rating: Int, _ text: String) -> Void
    ) {
        self.onSubmit = onSubmit
        self.submitTitle = submitTitle
        _rating = State(initialValue: initialRating)
        _content = State(initialValue: initialContent)
    }

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
                .foregroundStyle(.textPrimary)
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
                    Text(submitTitle)
                        .font(.headline)
                        .foregroundStyle(.textPrimary)
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
