//
//  FilterView.swift
//  DineHalal
//
//  Created by Iman Ikram on 3/24/25.
//

import SwiftUI

// Filter View (Popup)
struct FilterView: View {
    @Environment(\.presentationMode) var presentationMode // To close the sheet

    @State private var halalCertified = false
    @State private var userVerified = false
    @State private var thirdPartyVerified = false
    @State private var nearMe = false
    @State private var cityZip = ""
    @State private var middleEastern = false
    @State private var mediterranean = false
    @State private var southAsian = false
    @State private var american = false
    @State private var rating: Double = 3
    @State private var priceBudget = false
    @State private var priceModerate = false
    @State private var priceExpensive = false

    var body: some View {
        VStack {
            Text("Filter Restaurants")
                .font(.title2)
                .bold()
                .padding()
            
            Form {
                Section(header: Text("Halal Certification")) {
                    Toggle("Certified by Authority", isOn: $halalCertified)
                    Toggle("User Verified", isOn: $userVerified)
                    Toggle("Third-Party Verified", isOn: $thirdPartyVerified)
                }
                
                Section(header: Text("Location")) {
                    Toggle("Near Me", isOn: $nearMe)
                    TextField("Enter City/Zipcode", text: $cityZip)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Cuisine")) {
                    Toggle("Middle Eastern", isOn: $middleEastern)
                    Toggle("Mediterranean", isOn: $mediterranean)
                    Toggle("South Asian", isOn: $southAsian)
                    Toggle("American", isOn: $american)
                }
                
                Section(header: Text("Rating")) {
                    Slider(value: $rating, in: 1...5, step: 1)
                    Text("Min Rating: \(Int(rating)) stars")
                }
                
                Section(header: Text("Price Range")) {
                    Toggle("$ (Budget)", isOn: $priceBudget)
                    Toggle("$$ (Moderate)", isOn: $priceModerate)
                    Toggle("$$$ (Expensive)", isOn: $priceExpensive)
                }
            }
            
            Button(action: {
                presentationMode.wrappedValue.dismiss() // Close the filter popup
            }) {
                Text("Apply Filters")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.mud)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}
