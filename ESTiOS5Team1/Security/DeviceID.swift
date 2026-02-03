//
//  DeviceID.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/19/26.
//

import Foundation
import UIKit

/// 앱 설치 단위로 유지되는 디바이스 식별자를 관리합니다.
///
/// Keychain에 저장하여 앱 재설치 전까지 동일 값을 유지합니다.
final class DeviceID {
    /// 싱글턴 인스턴스입니다.
    static let shared = DeviceID()
    /// Keychain 저장 키입니다.
    private let key = "device_id"

    private init() {}

    /// Keychain에 저장된 값을 우선 사용하고, 없으면 새로 생성해 저장합니다.
    ///
    /// - Returns:
    ///   앱 설치 단위 디바이스 식별자 문자열
    var value: String {
        if let saved = KeychainStore.shared.read(key: key) {
            return saved
        } else {
            let new = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            KeychainStore.shared.save(key: key, value: new)
            return new
        }
    }
}
