//
///  PlacesApitest.swift
//  DineHalal
///  Created by Joanne on 4/1/25.

import SwiftUI

struct PlacesAPITest: View {
    @State private var response: String = "Testing..."
    private let apiKey = "YOUR_PLACES_KEY_HERE OR ASK ME FOR IT IF YOU CAN'T FIND ON THE CONSOLE"
    
    func testPlacesAPI() {
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=40.7128,-74.0060&radius=5000&type=restaurant&keyword=halal&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            response = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.response = "Error: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Response status code: \(httpResponse.statusCode)")
                }
                
                if let data = data,
                   let str = String(data: data, encoding: .utf8) {
                    print("Raw response: \(str)")
                    self.response = str
                }
            }
        }.resume()
    }
    
    var body: some View {
        VStack {
            Button("Test Places API") {
                testPlacesAPI()
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(8)
            
            ScrollView {
                Text(response)
                    .padding()
            }
        }
        .padding()
    }
}

