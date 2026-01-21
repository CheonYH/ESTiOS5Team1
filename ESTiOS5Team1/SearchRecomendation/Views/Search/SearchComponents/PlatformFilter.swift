//
//  PlatformFilter.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/7/26.
//

import SwiftUI

// MARK: - Platform Filter
struct PlatformFilter: View {
    @Binding var selectedPlatform: PlatformFilterType

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PlatformFilterType.allCases, id: \.self) { platform in
                    PlatformButton(
                        platform: platform,
                        isSelected: selectedPlatform == platform
                    ) {
                        selectedPlatform = platform
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Platform Filter Type
enum PlatformFilterType: String, CaseIterable {
    case all = "전체"
    case pc = "PC"
    case playstation = "PlayStation"
    case xbox = "Xbox"
    case nintendo = "Nintendo"
    case mobile = "Mobile"

    var iconColor: Color {
        switch self {
        case .all: return .purple
        case .pc: return .purple
        case .playstation: return .blue
        case .xbox: return .green
        case .nintendo: return .red
        case .mobile: return .cyan
        }
    }
}

// MARK: - Platform Capsule Button
struct PlatformButton: View {
    let platform: PlatformFilterType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                platformIcon
                    .font(.system(size: 14))

                Text(platform.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? platform.iconColor : Color.white.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var platformIcon: some View {
        switch platform {
        case .all:
            Image(systemName: "square.grid.2x2.fill")
        case .pc:
            Image(systemName: "desktopcomputer")
        case .playstation:
            Image(systemName: "playstation.logo")
        case .xbox:
            Image(systemName: "xbox.logo")
        case .nintendo:
            Image(systemName: "switch.2")
        case .mobile:
            Image(systemName: "iphone")
        }
    }
}
