//  FilterView.swift
//  DineHalal
//
//  Created by Iman Ikram on 3/24/25.
//  Edited by Chelsea on 4/5/25
//  Edited/Modified - Rosa

import SwiftUI

struct FilterView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var criteria: FilterCriteria
    var applyAction: (FilterCriteria) -> Void
    
    var body: some View {
        VStack {
            Text("Filter Restaurants")
                .font(.title2)
                .bold()
                .padding()
            
            Form {
                Section(header: Text("Halal Certification")) {
                    Toggle("Certified by Authority", isOn: $criteria.halalCertified)
                    Toggle("User Verified", isOn: $criteria.userVerified)
                    Toggle("Third-Party Verified", isOn: $criteria.thirdPartyVerified)
                }
                
                Section(header: Text("Location")) {
                    TextField("Enter City/Zipcode", text: $criteria.cityZip)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Cuisine")) {
                    Toggle("Middle Eastern", isOn: $criteria.middleEastern)
                    Toggle("Mediterranean", isOn: $criteria.mediterranean)
                    Toggle("South Asian", isOn: $criteria.southAsian)
                    Toggle("American", isOn: $criteria.american)
                }
                
                Section(header: Text("Rating")) {
                    Slider(value: $criteria.rating, in: 1...5, step: 1)
                    Text("Min Rating: \(Int(criteria.rating)) stars")
                }
                
                Section(header: Text("Price Range")) {
                    Toggle("$ (Budget)", isOn: $criteria.priceBudget)
                    Toggle("$$ (Moderate)", isOn: $criteria.priceModerate)
                    Toggle("$$$ (Expensive)", isOn: $criteria.priceExpensive)
                }
            }
            
            Button(action: {
                applyAction(criteria)
                presentationMode.wrappedValue.dismiss()
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
