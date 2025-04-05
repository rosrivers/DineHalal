**IMPORTANT**: Set up API Keys
   - Create a file named `APIKEYS.swift` in the `DineHalal` directory
   - Add the following code to the file, replacing with your actual API keys:
   ```swift
   import Foundation

   struct APIKEYS {
       static let MAPS_API_KEY = "YOUR_GOOGLE_MAPS_API_KEY FOUND ON THE GOOGLE CONSOLE OR ASK ME FOR IT"
       static let PLACES_API_KEY = "YOUR_GOOGLE_PLACES_API_KEY THE GOOGLE CONSOLE OR ASK ME FOR IT"
   }
   ```
   **Note**: This file is in `.gitignore` and should NEVER be committed to the repository - initially had key restrictions issues and had to regenerate them without it, please don't push the keys to github.

 Set up Firebase
   - Download your `GoogleService-Info.plist` from the Firebase console or ask a teammate for it.
   - Add it to the project (this file is also in `.gitignore`)
