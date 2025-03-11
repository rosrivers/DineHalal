//
//  Review.swift
//  Dine Halal
//
//  Created by Iman Ikram on 3/11/25.
//


import SwiftUI

struct Review: View {
    @State private var restaurantName: String = ""
    @State private var reviewText: String = ""
    @State private var rating: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AccentColor") // Background color
                    .ignoresSafeArea()
                
                VStack {
                    Text("Add a Review")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.darkBrown)
                        .padding(.top)

                    // Restaurant Name Input
                    TextField("Restaurant Name", text: $restaurantName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)

                    // Review Text Input
                    TextEditor(text: $reviewText)
                        .frame(height: 150)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)

                    // Rating Section
                    HStack {
                        Text("Rating:")
                            .bold()
                        ForEach(1..<6) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    rating = star
                                }
                        }
                    }
                    .padding()

                    // Submit Button
                    Button(action: {
                        // Handle review submission
                    }) {
                        Text("Submit Review")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.mud)
                            .foregroundColor(.beige)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    Spacer()

                    //  Bottom Navigation Bar (Same across all pages)
                    HStack {
                        NavigationButton(icon: "house.fill", title: "Home", destination: HomeScreen())
                        NavigationButton(icon: "heart.fill", title: "Favorites", destination: UserProfile())
                        NavigationButton(icon: "plus.circle.fill", title: "Add Review", destination: Review())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    .background(.mud)
                    .foregroundColor(.beige)
                }
            }
        }
    }
}

//  Reusable Navigation Button Component
struct NavigationButton<Destination: View>: View {
    let icon: String
    let title: String
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack {
                Image(systemName: icon)
                Text(title)
                    .font(.footnote)
            }
            .padding()
        }
    }
}

//  Preview
struct Review_Previews: PreviewProvider {
    static var previews: some View {
        Review()
    }
}
