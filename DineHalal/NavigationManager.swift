//
//  NavigationManager.swift
///  DineHalal
//
///  Created by Joanne on 3/25/25.

import SwiftUI

class NavigationStateManager: ObservableObject {
    @Published var selectedRestaurant: Restaurant?
    @Published var showingRestaurantDetail = false
}
