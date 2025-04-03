
///  Dine_HalalTests.swift
///  Dine HalalTests
///  Created by Joanne on 3/5/25.
/// Unit Testing - Each test method varifies a specific method in FirebaseService.swift
/// testFetchUserFavorites: Tests fetching user favorites.
/// testFetchUserReviews: Tests fetching user reviews.
/// testFetchAllRestaurants: Tests fetching all restaurants.
/// testFetchRestaurantReviews: Tests fetching reviews for a specific restaurant.

import XCTest
import Firebase
import FirebaseAuth
@testable import DineHalal

class FirebaseServiceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        /// Initialize Firebase
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        /// Sign in with a test user
        let email = "testuser@example.com"
        let password = "testpassword"
        let expectation = self.expectation(description: "Sign in")
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let error = error {
                XCTFail("Failed to sign in: \(error.localizedDescription)")
            } else {
                XCTAssertNotNil(result, "Result should not be nil")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    override func tearDown() {
        super.tearDown()
        /// Sign out the test user
        do {
            try Auth.auth().signOut()
        } catch {
            XCTFail("Failed to sign out: \(error.localizedDescription)")
        }
    }
    
    func testFetchUserFavorites() {
        let expectation = self.expectation(description: "FetchUserFavorites")
        
        FirebaseService.shared.fetchUserFavorites { favorites, error in
            XCTAssertNil(error, "Error should be nil")
            XCTAssertNotNil(favorites, "Favorites should not be nil")
            if let favorites = favorites {
                XCTAssertTrue(favorites.count >= 0, "Favorites should contain at least one item, or be empty")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testFetchUserReviews() {
        let expectation = self.expectation(description: "FetchUserReviews")
        
        FirebaseService.shared.fetchUserReviews { reviews, error in
            XCTAssertNil(error, "Error should be nil")
            XCTAssertNotNil(reviews, "Reviews should not be nil")
            if let reviews = reviews {
                XCTAssertTrue(reviews.count >= 0, "Reviews should contain at least one item, or be empty")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testFetchAllRestaurants() {
        let expectation = self.expectation(description: "FetchAllRestaurants")
        
        FirebaseService.shared.fetchAllRestaurants { restaurants, error in
            XCTAssertNil(error, "Error should be nil")
            XCTAssertNotNil(restaurants, "Restaurants should not be nil")
            if let restaurants = restaurants {
                XCTAssertTrue(restaurants.count >= 0, "Restaurants should contain at least one item, or be empty")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testFetchRestaurantReviews() {
        let expectation = self.expectation(description: "FetchRestaurantReviews")
        
        FirebaseService.shared.fetchRestaurantReviews(restaurantId: "testRestaurantId") { reviews, error in
            XCTAssertNil(error, "Error should be nil")
            XCTAssertNotNil(reviews, "Reviews should not be nil")
            if let reviews = reviews {
                XCTAssertTrue(reviews.count >= 0, "Reviews should contain at least one item, or be empty")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}
