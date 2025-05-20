<p align="center"> 
  <img src="logonobackground.png" alt="DineHalal" width="80px" height="80px">
</p>
<h1 align="center"> DineHalal </h1>
<h3 align="center"> CSCI 499.05 Advanced Applications: Capstone Course in Computer Science </h3>
<h4 align="center"> Capstone Project - <a href="https://hunter.cuny.edu/">Hunter College</a> (Spring 2025) </h4>
<h5 align="center"> Authors: Chelsea Bhuiyan, Joana Osei, Iman Ikram, Victoria Noa, Rosa Rivera </h5>

![----------------------------------------------------------](https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png)

<!-- ABOUT THE PROJECT -->
<h2 id="about-the-project"> :pencil: About The Project</h2>
<p align="justify"> 
  
  Do you ever get tired of restaurants **falsely claiming** they’re halal? Meet Layla, a college student who follows a halal diet. After class, she wants to grab a quick meal but struggles to find **verified halal options**. Google and Yelp list restaurants as “halal,” but many aren’t actually **certified**. She wastes time calling restaurants or checking multiple apps, only to find out they **don’t meet her dietary needs**.  

DineHalal is the solution—a platform designed to make discovering **verified halal food** easier. It provides:  
- **Accurate Halal Listings** – Every restaurant is **verified** to ensure it truly meets halal standards.  
- **Smart Search & Filters** – Find places based on **location, cuisine, and dietary preferences**.  
- **Community Reviews** – Read experiences from other **halal-conscious diners** before you go.  
- **Menus, Reservations & Delivery** – Access restaurant menus, book tables, or **order food directly**.  

No more **second-guessing**. With DineHalal, finding **authentic halal food** is simple, reliable, and stress-free.
</p>

![----------------------------------------------------------](https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png)

<!-- TECHNOLOGIES USED -->
<h2 id="technologies-used"> Technologies Used </h2>

- **Xcode** for building and testing the iOS application  
- **SwiftUI** for iOS development  
- **Google Places/Maps API** for restaurant data  
- **Firestore Firebase** for database infrastructure  
- **Firebase Authentication** for secure user login  
- **Figma** for UI prototyping  
- **GitHub** for version control and collaboration among team members  

![----------------------------------------------------------](https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png)

<!-- TO DO - DONE LIST BELOW -->
<h2 id="to-do"> To Do </h2>

# DineHalal Authentication Setup 🔐

## Authentication Progress ✅
- [x] Email Authentication
- [x] Google Sign-In Implementation 
- [x] Info.plist Configuration
- [x] SignIniew 
## Google Sign-In Setup Guide 

After pulling the latest changes, follow these steps to set up Google Sign-In:

1. In Xcode, locate the `Dine-Halal-Info.plist` file in the project navigator, make sure the file name is correct, it may be `DineHalal-Info.plist`

2. Add the Info.plist to your target:
   - Click on your project in the navigator
   - Select the "Dine Halal" target
   - Go to "Build Phases"
   - Expand "Copy Bundle Resources"
   - Click the "+" button
   - Choose `Dine-Halal-Info.plist`
   - Click "Add"

3. Verify the setup:
   - The Google Sign-In configuration should now work automatically
   - If you see any issues, make sure the `Dine-Halal-Info.plist` is included in your target's "Copy Bundle Resources"

Note: The Info.plist file contains the necessary Google Sign-In configuration, and this setup needs to be done only once after pulling these changes.


# DineHalal Map Integration and UI Updates 🗺️

## Recent Updates (March 25, 2025) 
- [x] Google Maps Integration
- [x] User Login Display
- [x] Basic Restaurant Location Display Structure (done relies on restaurant data not made yet)

## Google Maps Setup Complete
The app now includes:
- Interactive map display
- Location-based restaurant discovery (relies on restaurant data- not integrated yet)

## Next Steps 
- [x] Restaurant API Integration
- [x] Real-time Location Updates

Note: The Google Maps integration is now complete with the necessary API configuration.
---
# Places API Integration

This module handles the integration of Google Places API within the DineHalal app to fetch and display halal restaurant data.

## Overview

- Fetches halal restaurants based on user location.
- Retrieves details including restaurant name, address, photo, and coordinates (geolocation).
- Handles API requests, response parsing, and error management.

## How It Works

1. **Location Access**:  
   The app requests the user's permission to access location data.

2. **API Request**:  
   Using the user's coordinates/loaction, the app sends a request to the Google Places API with appropriate filters (e.g., `type=restaurant`, `keyword=halal`).

3. **Data Processing**:  
   The response is parsed to extract relevant fields:
   - Name
   - Address
   - Photo reference
   - Latitude & longitude

4. **Display**:  
   Restaurants are rendered on the Home screen, with details and map integration available on the Restaurant Details page.

## Configuration

- Set your Google Places API Key in the project’s configuration file or environment variables.
- Ensure location permissions are handled in `Info.plist`for iOS.

## Relevant Files

- `PlacesService.swift`: Handles API requests and parsing.
- `RestaurantListViewModel.swift`: Manages state and data binding for the restaurant list.
- `RestaurantDetailView.swift`: Displays detailed restaurant information including map.

## Error Handling

- Handles network errors, invalid API responses, and missing data gracefully.
- Displays user-friendly error messages if data cannot be loaded.

## Notes

- Be mindful of Google API rate limits.
- API keys should be kept secure and never exposed in the client app.

# Halal Verification System

This module implements a dual-layer halal verification feature for DineHalal, ensuring the trustworthiness of restaurant listings.

## Overview

- Combines **official certification** with **community-driven verification**.
- Displays verification badges on restaurant profiles.

## How It Works

### 1. Official Verification

- Imports and parses official halal certification lists (PDF converted to CSV) from recognized authority (The New York State of Agriculture Department).
- Matches restaurant names and/or addresses with imported data.
- Restaurants with a match are marked as "Officially Verified" in the UI.

### 2. Community Verification

- Allows users to submit feedback or vote on a restaurant's halal status.
- Aggregates user input to determine "Community Verified" status.

## Configuration

- Official certification data should be uploaded in supported formats (CSV/PDF) and placed in the designated directory.
- Community verification is managed through the app’s interface and backed by the database.

## Relevant Files

- `HalalVerificationService.swift`: Handles certification parsing and verification logic.
- `CommunityVerificationModel.swift`: Manages user-submitted verification and voting.
- `RestaurantDetailView.swift`: Renders verification badges and handles user input.

## Error Handling

- Handles conflicting or ambiguous verification statuses.
- Provides clear messaging in the UI when verification is pending or disputed. 

## Notes
- Regular updates to official certification lists are recommended.
- Community input is moderated to prevent abuse or misinformation and condinated voting.

