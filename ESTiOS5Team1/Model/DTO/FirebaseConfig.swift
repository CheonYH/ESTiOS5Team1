//
//  FirebaseConfig.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/19/26.
//

import Foundation

struct FirebaseConfig: Decodable {
    let apiKey: String
    let appId: String
    let gcmSenderId: String
    let projectId: String
    let storageBucket: String?
    let clientId: String
}
