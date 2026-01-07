//
//  Platform.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/7/26.
//


import Foundation

// MARK: - Platform Enum
enum Platform: String {
    case playstation = "playstation"
    case xbox = "xbox"
    case pc = "pc"
    case nintendo = "nintendo"
    
    var icon: String {
        switch self {
        case .playstation: return "playstation.logo"
        case .xbox: return "xbox.logo"
        case .pc: return "pc"
        case .nintendo: return "nintendo.logo"
        }
    }
}