//
//  ProfileDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/xx/26.
//

import Foundation

/// 프로필 생성/수정 요청 모델입니다.
struct ProfileRequest: Codable, Hashable {
    /// 사용자 닉네임입니다.
    let nickname: String
    /// 프로필 이미지 URL 문자열입니다.
    let avatarUrl: String
}

/// 프로필 조회/응답 모델입니다.
struct ProfileResponse: Codable, Hashable {
    /// 프로필 ID입니다.
    let id: Int
    /// 사용자 ID입니다.
    let userId: Int
    /// 사용자 닉네임입니다.
    let nickname: String
    /// 프로필 이미지 URL 문자열입니다.
    let avatarUrl: String
}
