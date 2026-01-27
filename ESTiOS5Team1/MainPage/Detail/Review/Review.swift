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
            
            TextField("게임의 평가를 남겨주세요.", text: $content, axis: .vertical)
                .lineLimit(3...8)
                .focused($focused)
                .textFieldStyle(.plain)
                .padding(5)
                .foregroundStyle(.white)

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
