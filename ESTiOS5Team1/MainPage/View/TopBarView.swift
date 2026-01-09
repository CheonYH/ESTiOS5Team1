//
//  topBarView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//

import SwiftUI

struct TopBarView: View {
    @State var imageColor: Color = .white
    @State var textColor: Color = .white

    var body: some View {
            HStack {
                Button {

                } label: {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(imageColor)
                }

                Spacer()

                Image(systemName: "book")
                    .foregroundStyle(.purple)

                Text("GameVault")
                    .foregroundStyle(textColor)

                Spacer()

                Button {
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(imageColor)
                }

            }
            .padding(.horizontal, 30)

            Divider()
                .frame(height: 1)
                .background(Color.white.opacity(0.2))
    }
}

#Preview {
    TopBarView()
}
