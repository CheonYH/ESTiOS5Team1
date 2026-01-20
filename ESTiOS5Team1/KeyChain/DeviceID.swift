//
//  DeviceID.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/19/26.
//

import Foundation
import UIKit

final class DeviceID {
    static let shared = DeviceID()
    private let key = "device_id"

    private init() {}

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
