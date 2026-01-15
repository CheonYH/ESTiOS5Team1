//
//  topBarView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//

import SwiftUI

struct TopBarView: View {
    
    var body: some View {
            HStack {
                Button {

                } label: {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.symbolPrimary)
                }

                Spacer()

                Image(systemName: "book")
                    .foregroundStyle(.purple)

                Text("GameVault")
                    .foregroundStyle(.textPrimary)

                Spacer()

                Button {
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.symbolPrimary)
                }

            }
            .padding(.horizontal, Spacing.pv10)

            Divider()
                .frame(height: 1)
                .background(.textPrimary.opacity(0.2))
    }
}

#Preview {
    TopBarView()
}
