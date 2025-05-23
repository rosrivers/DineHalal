///  Restaurant.swift
///  Dine Halal
///  Created by Joanne on 3/19/25.
///  Edited by Rosa to include opening hours / closing

import Foundation

struct Restaurant: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let rating: Double
    let numberOfRatings: Int
    let priceLevel: Int?
    let vicinity: String
    let isOpenNow: Bool
    let openUntilTime: String? // added for "Open until [time]"
    let photoReference: String?
    let placeId: String
    let latitude: Double
    let longitude: Double
    let address: String

    enum CodingKeys: String, CodingKey {
        case name
        case rating
        case numberOfRatings = "user_ratings_total"
        case priceLevel = "price_level"
        case vicinity
        case geometry
        case openingHours = "opening_hours"
        case photos
        case placeId = "place_id"
    }

    struct GeometryKeys: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }

        static let location = GeometryKeys(stringValue: "location")!
        static let lat = GeometryKeys(stringValue: "lat")!
        static let lng = GeometryKeys(stringValue: "lng")!
    }

    enum OpeningHoursKeys: String, CodingKey {
        case openNow = "open_now"
        case periods
    }

    struct Period: Codable {
        struct TimeData: Codable {
            let day: Int
            let time: String
        }
        let open: TimeData
        let close: TimeData
    }

    struct PhotoData: Codable {
        let photoReference: String
        
        enum CodingKeys: String, CodingKey {
            case photoReference = "photo_reference"
        }
    }
    
    // JSON structs matching the API
    struct GooglePlacesResponse: Decodable {
      let results: [PlaceResult]
    }
    struct PlaceResult: Decodable {
      let place_id: String
      let name: String
      let rating: Double?
      let geometry: Geometry
      let photos: [Photo]?
    }
    struct Geometry: Decodable {
      let location: Location
    }
    struct Location: Decodable {
      let lat: Double
      let lng: Double
    }
    struct Photo: Decodable {
      let photo_reference: String
    }
    
    // Initializer for creating Restaurant objects from Firestore data
    init(
        id: String,
        name: String,
        rating: Double,
        numberOfRatings: Int,
        priceLevel: Int?,
        vicinity: String,
        isOpenNow: Bool = false,
        openUntilTime: String? = nil,
        photoReference: String? = nil,
        placeId: String,
        latitude: Double,
        longitude: Double,
        address: String
    ) {
        self.id = id
        self.name = name
        self.rating = rating
        self.numberOfRatings = numberOfRatings
        self.priceLevel = priceLevel
        self.vicinity = vicinity
        self.isOpenNow = isOpenNow
        self.openUntilTime = openUntilTime
        self.photoReference = photoReference
        self.placeId = placeId
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.placeId = try container.decode(String.self, forKey: .placeId)
        self.id = self.placeId
        self.name = try container.decode(String.self, forKey: .name)
        self.rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0.0
        self.numberOfRatings = try container.decodeIfPresent(Int.self, forKey: .numberOfRatings) ?? 0
        self.priceLevel = try container.decodeIfPresent(Int.self, forKey: .priceLevel)
        self.vicinity = try container.decode(String.self, forKey: .vicinity)
        
        let geometryContainer = try container.nestedContainer(keyedBy: GeometryKeys.self, forKey: .geometry)
        let locationContainer = try geometryContainer.nestedContainer(keyedBy: GeometryKeys.self, forKey: .location)
        self.latitude = try locationContainer.decode(Double.self, forKey: .lat)
        self.longitude = try locationContainer.decode(Double.self, forKey: .lng)
        
        var isOpenNowLocal = false
        var openUntilTimeLocal: String? = nil

        if let openingHoursContainer = try? container.nestedContainer(keyedBy: OpeningHoursKeys.self, forKey: .openingHours) {
            isOpenNowLocal = (try? openingHoursContainer.decode(Bool.self, forKey: .openNow)) ?? false

            if let periods = try? openingHoursContainer.decodeIfPresent([Period].self, forKey: .periods) {
                openUntilTimeLocal = Self.findTodayClosingTime(from: periods)
            }
        }

        self.isOpenNow = isOpenNowLocal
        self.openUntilTime = openUntilTimeLocal

        if let photos = try? container.decode([PhotoData].self, forKey: .photos) {
            self.photoReference = photos.first?.photoReference
        } else {
            self.photoReference = nil
        }

        self.address = self.vicinity
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(rating, forKey: .rating)
        try container.encode(numberOfRatings, forKey: .numberOfRatings)
        try container.encode(vicinity, forKey: .vicinity)
        try container.encode(placeId, forKey: .placeId)

        var geometryContainer = container.nestedContainer(keyedBy: GeometryKeys.self, forKey: .geometry)
        var locationContainer = geometryContainer.nestedContainer(keyedBy: GeometryKeys.self, forKey: .location)
        try locationContainer.encode(latitude, forKey: .lat)
        try locationContainer.encode(longitude, forKey: .lng)

        var openingHoursContainer = container.nestedContainer(keyedBy: OpeningHoursKeys.self, forKey: .openingHours)
        try openingHoursContainer.encode(isOpenNow, forKey: .openNow)
    }

    // MARK: - Helper Functions

    private static func findTodayClosingTime(from periods: [Period]) -> String? {
        let weekday = (Calendar.current.component(.weekday, from: Date()) + 6) % 7 // Fix to make Sunday=0
        if let todayPeriod = periods.first(where: { $0.open.day == weekday }) {
            return formatTime(todayPeriod.close.time)
        }
        return nil
    }

    private static func formatTime(_ militaryTime: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HHmm"
        guard let date = dateFormatter.date(from: militaryTime) else { return militaryTime }

        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(placeId)
    }

    static func == (lhs: Restaurant, rhs: Restaurant) -> Bool {
        return lhs.id == rhs.id && lhs.placeId == rhs.placeId
    }
}
