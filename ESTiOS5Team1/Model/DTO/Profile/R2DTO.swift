//
//  R2DTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/xx/26.
//

import Foundation

/// R2 업로드 프리사인 URL 발급 요청 모델입니다.
struct R2PresignRequest: Codable, Hashable {
    /// 업로드할 파일명입니다.
    let filename: String
    /// 만료 시간(초)입니다.
    let expiresIn: Int
}

/// R2 업로드 프리사인 URL 발급 응답 모델입니다.
struct R2PresignResponse: Codable, Hashable {
    /// 업로드용 프리사인 URL입니다.
    let uploadUrl: String
    /// R2 객체 키입니다.
    let key: String
    /// 공개 접근 URL입니다. (없을 수 있음)
    let publicUrl: String?
    /// 만료 시간(초)입니다.
    let expiresIn: Int
}
