//
//  LoadableList.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/16/26.
//

import SwiftUI

/// 로딩/에러/정상 상태를 공통 UI 패턴으로 감싸는 리스트 컨테이너입니다.
///
/// - 역할:
///   - `isLoading`일 때 로딩 인디케이터를 보여줍니다.
///   - `error`가 존재하면(필요 시) 에러 UI를 표시합니다.
///   - 정상 상태에서는 `NavigationLink`로 row → destination 이동을 제공합니다.
///
/// - Generic Parameters:
///   - Items: `Identifiable` 원소를 가진 컬렉션
///   - Row: 각 아이템 셀 View
///   - Destination: 네비게이션으로 이동할 목적지 View
struct LoadableList<Items: RandomAccessCollection, Row: View, Destination: View>: View where Items.Element: Identifiable {
    /// 로딩 중 여부입니다.
    let isLoading: Bool
    /// 에러 객체(있을 경우)입니다.
    let error: Error?
    /// 표시할 데이터 컬렉션입니다.
    let items: Items
    
    /// 표시 개수를 제한할 때 사용하는 옵션입니다. (nil이면 전체)
    var limit: Int?
    /// 로딩 인디케이터에 함께 표시할 텍스트입니다.
    var loadingText: String = "로딩 중"
    
    /// 아이템을 탭했을 때 이동할 목적지 뷰를 생성합니다.
    let destination: (Items.Element) -> Destination
    /// 아이템 한 줄(row) UI를 생성합니다.
    let row: (Items.Element) -> Row
    
    var body: some View {
        if isLoading && Array(items).isEmpty {
            ProgressView(loadingText)
        } else if error != nil {
            // error UI
        } else {
            let list = Array(items)
            ForEach(prefix(list)) { item in
                NavigationLink(destination: destination(item)) {
                    row(item)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    /// `limit`이 지정된 경우 배열을 앞에서부터 잘라 반환합니다.
    ///
    /// - Parameter array: 원본 배열
    /// - Returns: 제한이 적용된 배열
    private func prefix(_ array: [Items.Element]) -> [Items.Element] {
        guard let limit else { return array }
        return Array(array.prefix(limit))
    }
}
