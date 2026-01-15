//
//  DetailTopBar.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//

import SwiftUI

struct DetailTopBar: View {
    @State var isHeart: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.backward")
                    .foregroundStyle(.textPrimary)
            }
            
            Spacer()
            
            Button {
                isHeart = !isHeart
            } label: {
                Image(systemName: isHeart ? "heart.fill" : "heart")
                    .foregroundStyle(.textPrimary)
            }
            .padding(.horizontal)
            
            Button {
                
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(.textPrimary)
            }
        }
        .navigationBarBackButtonHidden()
        .padding(.horizontal, Spacing.pv10)
        
        Divider()
            .frame(height: 1)
            .background(.textPrimary.opacity(0.2))
    }
}

#Preview {
    DetailTopBar()
        .background(.BG)
}
