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


                    //BottomNavBar()
                }
            }
        }
    }
}

// Preview
struct Review_Previews: PreviewProvider {
    static var previews: some View {
        Review()
    }
}
