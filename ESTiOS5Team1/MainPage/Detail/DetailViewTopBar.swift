//
//  DetailViewTopBar.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//

import SwiftUI

struct DetailViewTopBar: View {
    @State var isHeart: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.backward")
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            Button {
                isHeart = !isHeart
            } label: {
                Image(systemName: isHeart ? "heart.fill" : "heart")
                    .foregroundStyle(.white)
            }
            .padding(.horizontal)
            
            Button {
                
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(.white)
            }
        }
        .navigationBarBackButtonHidden()
        .padding(.horizontal, 30)
        
        Divider()
            .frame(height: 1)
            .background(Color.white.opacity(0.2))
    }
}

#Preview {
    DetailViewTopBar()
}
