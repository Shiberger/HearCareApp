# HearCare

<div align="center">
  <img src="screenshots/app_logo.png" alt="HearCare Logo" width="150" />
  <h3>Hearing Test & Monitoring App</h3>
  <p>A comprehensive iOS application for hearing testing and monitoring at home</p>
</div>

## 📋 Overview

HearCare is a mobile application designed to provide accessible hearing tests and monitoring for users in their everyday environment. With its intuitive interface and scientifically-based testing approach, HearCare helps users monitor their hearing health over time and detect potential hearing issues early.

### 🌟 Key Features

- **Pure-tone Audiometry Tests**: Comprehensive hearing tests across multiple frequencies
- **Device Calibration**: Advanced calibration system to ensure accurate test results
- **Ambient Noise Detection**: Monitors environmental noise to ensure optimal testing conditions
- **Hearing Health Profile**: Personalized hearing health tracking and analysis
- **Test History**: Track hearing changes over time with detailed historical data
- **Comprehensive Analysis**: Detailed audiogram and analysis of hearing test results
- **Personalized Recommendations**: Get custom recommendations based on your hearing profile

## 🖼️ Screenshots

<div align="center">
  <img src="https://github.com/user-attachments/assets/93e3d27c-5397-42a3-abdc-39fc5365e5ba"/>
  <img src="https://github.com/user-attachments/assets/58b6599f-a1ca-4be6-b217-358dedb8fdc7"/>
</div>

## 🛠️ Technologies Used

- **SwiftUI**: Modern declarative UI framework for iOS
- **Firebase/Firestore**: Backend database for user data and test results
- **Firebase Authentication**: User authentication and profile management
- **AVFoundation**: Audio generation and processing
- **CoreML**: Machine learning model for hearing classification
- **Charts**: Visualization of audiogram data
- **Google Sign-In**: Authentication system

### Firebase Architecture

The app uses Firebase as its backend with the following structure:

```
firestore/
├── users/
│   ├── {userId}/
│   │   ├── testResults/
│   │   │   ├── {testId}/
│   │   │   │   ├── testDate
│   │   │   │   ├── rightEarClassification
│   │   │   │   ├── leftEarClassification
│   │   │   │   ├── rightEarData[]
│   │   │   │   ├── leftEarData[]
│   │   │   │   └── recommendations[]
│   │   ├── userData/
│   │   │   ├── lastTest/
│   │   │   └── ...
│   │   ├── createdAt
│   │   ├── email
│   │   ├── name
│   │   ├── phoneNumber
│   │   ├── age
│   │   ├── gender
│   │   ├── photoURL
│   │   └── hearingConditions[]
```

## 📊 How It Works

HearCare uses a modified Hughson-Westlake procedure to determine hearing thresholds:

1. **Calibration**: Users first calibrate their device with their headphones to ensure accurate testing
2. **Environment Check**: The app checks ambient noise levels to ensure optimal testing conditions
3. **Test Procedure**: 
   - Plays tones at different frequencies (500Hz, 1kHz, 2kHz, 4kHz, 8kHz)
   - Systematically adjusts volume levels using an adaptive procedure
   - Determines the minimum volume at which a user can hear each frequency
4. **Result Analysis**: Converts test responses into clinically relevant hearing levels
5. **Visualization**: Displays results in a standard audiogram format with personalized insights

## 🚀 Getting Started

### Prerequisites

- Xcode 14.0+
- iOS 15.0+
- CocoaPods

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/hearcare-app.git
```

2. Navigate to the project directory
```bash
cd hearcare-app
```

3. Install dependencies via Swift Packages

4. Set up Firebase
   - Go to the [Firebase Console](https://console.firebase.google.com/)
   - Create a new project (or use an existing one)
   - Add an iOS app to your Firebase project
     - Use the bundle ID: `hannarong.HearCareApp` (or update to your own)
     - Download the `GoogleService-Info.plist` file
     - Place the file in the root directory of your Xcode project
   - Enable the services required for the app:
     - Authentication (Google Sign-In)
     - Firestore Database
     - Firebase Storage (for user profile images)
   - Set up Google Sign-In
     - In Firebase Console, go to Authentication > Sign-in method
     - Enable Google Sign-In
     - Configure your OAuth consent screen in Google Cloud Console
     - Add your reversed client ID to the URL types in Xcode project's Info.plist

5. Configure Firebase Security Rules
   - Go to Firestore Database > Rules and set up appropriate security rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, update, delete: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null;
      
      match /testResults/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /userData/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

6. Build and run the app on your preferred simulator or device

## 🧪 Testing Best Practices

For accurate testing results:

- Use quality headphones (over-ear preferred)
- Test in a quiet environment (<35dB ambient noise)
- Complete the device calibration procedure
- Set device volume to 50-70%
- Follow the on-screen instructions carefully
- Be honest about which tones you can and cannot hear

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⚠️ Disclaimer

HearCare is intended as a screening tool only and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of a qualified healthcare provider with any questions you may have regarding hearing health or conditions.

## 📞 Contact

Hannarong Kaewkiriya - [@Linkedin](www.linkedin.com/in/hannarong-hnk) - hannarong.tonkra@gmail.com

Project Link: [https://github.com/shiberger/hearcare-app](https://github.com/shiberger/hearcare-app)
