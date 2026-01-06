//
//  IGDBConfig.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import Foundation

enum IGDBConfig {
    static let clientID: String = {
        guard let value = Bundle.main.object(
            forInfoDictionaryKey: "IGDBClientID"
        ) as? String else {
            fatalError("IGDBClientID not set")
        }
        return value
    }()

    static let accessToken: String = {
        guard let value = Bundle.main.object(
            forInfoDictionaryKey: "IGDBAccessToken"
        ) as? String else {
            fatalError("IGDBAccessToken not set")
        }
        return value
    }()
}
