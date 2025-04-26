
///  RestaurantCardwithVerification.swift
///  DineHalal
///  Created by Joanne on 4/20/25.

import SwiftUI


struct RestaurantCardWithVerification: View {
    let restaurant: Restaurant
    let verificationResult: VerificationResult
    
    
    var body: some View {
        VStack {
            if let photoReference = restaurant.photoReference {
                AsyncImage(url: GoogleMapConfig.getPhotoURL(photoReference: photoReference)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        Image("food_placeholder")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        Image("food_placeholder")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .frame(height: 110)
                .frame(maxWidth: .infinity)
                .cornerRadius(10, corners: [.topLeft, .topRight])
            } else {
                Image("food_placeholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 110)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(10, corners: [.topLeft, .topRight])
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(restaurant.name)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.darkBrown)
                
                // Rating-----RAAAAAAAAAAAAH!!!
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(restaurant.rating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.system(size: 10))
                    }
                    Text(String(format: "%.1f", restaurant.rating))
                        .font(.system(size: 10))
                        .foregroundColor(.darkBrown)
                }
                
                // Verification badge
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.mud)
                        .font(.system(size: 12))
                    Text("Verified Halal")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.mud)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.mud.opacity(0.7), lineWidth: 1)
        )
        .shadow(radius: 2)
    }
}

// Helper extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
