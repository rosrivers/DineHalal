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
- [ ] Restaurant API Integration
- [ ] Real-time Location Updates

Note: The Google Maps integration is now complete with the necessary API configuration.
---
## Verification System 🔍
- **PDF Parser Integration** - Implemented a robust PDF parsing system to extract halal certification data.
- **Restaurant Verification** - Built automated verification service that cross-references Yelp restaurant data with halal registration information.
- **Data Model Layer** - structured models for HalalEstablishment and Restaurant to ensure reliable data handling.
