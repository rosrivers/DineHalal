//
//  StarRatingPicker.swift
//  DineHalal
//
//  Created by Chelsea Bhuiyan on 5/4/25.
//

import SwiftUI

struct StarRatingPicker: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.yellow)
                    .onTapGesture {
                        rating = star
                    }
            }
        }
        .padding(.vertical, 4)
    }
}
