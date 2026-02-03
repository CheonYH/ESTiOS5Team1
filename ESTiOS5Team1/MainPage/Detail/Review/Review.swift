//
//  Review.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/23/26.
//

import SwiftUI

/// 리뷰 작성/수정 폼(별점 + 텍스트 입력 + 제출 버튼)입니다.
///
/// - 역할:
///   - 별점 선택(`StarRatingPicker`)과 리뷰 내용을 입력받습니다.
///   - 제출 시 입력값을 trim 한 뒤 `onSubmit`으로 전달합니다.
///
/// - Note:
///   이 뷰는 서버 통신을 직접 수행하지 않고, 외부에서 주입받은 `onSubmit` 클로저로만 결과를 전달합니다.
struct Review: View {
    /// 제출 버튼을 눌렀을 때 호출되는 콜백입니다.
    ///
    /// - Parameters:
    ///   - rating: 1~5 사이 별점
    ///   - text: 공백/개행이 trim 된 리뷰 내용
    let onSubmit: (_ rating: Int, _ text: String) -> Void
    /// 제출 버튼에 표시할 타이틀입니다. (예: "등록", "수정")
    let submitTitle: String
    /// 현재 선택된 별점 값입니다.
    @State private var rating: Int
    /// 현재 입력된 리뷰 텍스트입니다.
    @State private var content: String
    /// 텍스트 필드 포커스 상태입니다.
    @FocusState private var focused: Bool
    /// 초기 값(별점/내용)과 제출 버튼 타이틀을 설정합니다.
    ///
    /// - Parameters:
    ///   - initialRating: 초기 별점(기본 1)
    ///   - initialContent: 초기 리뷰 내용(기본 빈 문자열)
    ///   - submitTitle: 제출 버튼 타이틀(기본 "등록")
    ///   - onSubmit: 제출 콜백
    
    
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
