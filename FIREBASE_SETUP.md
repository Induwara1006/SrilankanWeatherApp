# Firebase Setup Instructions

## Steps to complete Firebase configuration:

### 1. Enable Authentication
1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project "SrilankaApp"
3. Click on "Authentication" in the left sidebar
4. Click "Get Started"
5. Enable "Anonymous" sign-in method
   - Click on "Anonymous"
   - Toggle the "Enable" switch
   - Click "Save"

### 2. Enable Firestore Database
1. In Firebase Console, click on "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a Cloud Firestore location (closest to Sri Lanka: `asia-south1` - Mumbai)
5. Click "Enable"

### 3. Set Firestore Security Rules
1. In Firestore, go to "Rules" tab
2. Replace the rules with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /regions/{regionId} {
      allow read: if true;
      
      allow write: if request.auth != null
                   && request.resource.data.keys().hasOnly([
                      'name', 'lat', 'lng', 'status', 'updatedAt', 'updatedBy'
                   ])
                   && request.resource.data.name is string
                   && request.resource.data.lat is number
                   && request.resource.data.lng is number
                   && request.resource.data.status in ['sunny','rainy','cloudy']
                   && request.resource.data.updatedBy == request.auth.uid
                   && request.time == request.resource.data.updatedAt;
    }
  }
}
```

3. Click "Publish"

### 4. Run the App
Once the above steps are complete:
1. The app will connect to Firebase
2. On first launch, tap "Seed Regions" to populate all 25 districts
3. Tap any district marker to update its weather
4. Changes will be visible to all users in realtime!

## How the App Works:
- **Sunny** 🌞 - Orange circle with sun icon
- **Rainy** 💧 - Blue circle with water drop icon  
- **Cloudy** ☁️ - Grey circle with cloud icon

Users can tap any district to update the weather, and the latest update from any user will be displayed for everyone.
