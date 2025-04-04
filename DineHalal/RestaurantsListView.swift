//
//  DineHalal
//
//  Created by rosa <3 and Victoria on 4/4/25.
//
import SwiftUI

struct PlacesResponse: Codable {
    let results: [Place]
}

struct Place: Codable, Identifiable {
    var id: String { name }
    let name: String
    let vicinity: String
}

class GooglePlacesService {
    private let apiKey = "AIzaSyCaAElzJ5HtVCuy0q7v3TnKWx8qFNXu9b0"
    
    func fetchNearbyRestaurants(latitude: Double, longitude: Double, completion: @escaping ([Place]) -> Void) {
        let radius = 1500
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(latitude),\(longitude)&radius=\(radius)&type=restaurant&key=\(apiKey)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let placesResponse = try? JSONDecoder().decode(PlacesResponse.self, from: data)
            else { return }
            
            DispatchQueue.main.async {
                completion(placesResponse.results)
            }
        }.resume()
    }
}

struct RestaurantsListView: View {
    @State private var places: [Place] = []
    let latitude = 40.7128
    let longitude = -74.0060
    
    var body: some View {
        NavigationView {
            List(places) { place in
                VStack(alignment: .leading) {
                    Text(place.name).font(.headline)
                    Text(place.vicinity).font(.subheadline).foregroundColor(.gray)
                }
            }
            .navigationTitle("Nearby Restaurants")
            .onAppear {
                GooglePlacesService().fetchNearbyRestaurants(latitude: latitude, longitude: longitude) { fetchedPlaces in
                    self.places = fetchedPlaces
                }
            }
        }
    }
}


