# 🐾 PetPulse

<div align="center">

**An innovative Flutter application dedicated to keeping track of your pets and connecting pet lovers**

[![Flutter](https://img.shields.io/badge/Flutter-3.5.4+-02569B? logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5.4+-0175C2? logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Not%20Specified-lightgrey)](#)

</div>

---

## 📖 About PetPulse

PetPulse is a comprehensive pet management and matching application designed to help pet owners monitor their pets' health, activities, and connect with other pet lovers in their area. Built with Flutter, PetPulse offers a seamless cross-platform experience on Android, iOS, Web, Windows, and Linux.

## ✨ Features

### 🏥 Pet Health Monitoring
- Track pet health metrics and vital information
- Set reminders for vet visits and medication schedules
- Monitor pet activities and daily routines
- Maintain comprehensive pet profiles

### 🐕 Pet Matching & Social
- Connect with other pet owners in your area
- Pet matching functionality for socialization and playdates
- Real-time chat system for communication
- Share pet profiles with the community

### 📍 Location Services
- Google Maps integration for finding nearby pet services
- Location-based pet owner discovery
- Track pet-friendly locations

### 🔔 Smart Notifications
- Feature-based notification system
- Reminder notifications for important pet care tasks
- Real-time chat notifications

### 🔐 Authentication
- Secure Firebase authentication
- User signup and login functionality
- Protected user profiles

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed: 
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.5.4 or higher)
- [Dart SDK](https://dart.dev/get-dart) (3.5.4 or higher)
- A code editor (VS Code, Android Studio, or IntelliJ IDEA)
- Firebase account for backend services

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/minipetorg/c-petPulse.git
   cd c-petPulse
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add your Firebase configuration files: 
     - Android: `google-services.json` in `android/app/`
     - iOS: `GoogleService-Info.plist` in `ios/Runner/`
     - Web: Update Firebase config in `web/index.html`

4. **Set up Google Maps API**
   - Obtain a Google Maps API key
   - Update the API key in `web/index.html` (currently using placeholder)
   - Configure API keys for Android and iOS platforms

5. **Run the application**
   ```bash
   # For development
   flutter run

   # For specific platform
   flutter run -d chrome        # Web
   flutter run -d windows       # Windows
   flutter run -d linux         # Linux
   flutter run -d android       # Android
   flutter run -d ios           # iOS
   ```

---

## 🏗️ Project Structure

```
c-petPulse/
├── android/              # Android platform files
├── ios/                  # iOS platform files
├── linux/                # Linux platform files
├── windows/              # Windows platform files
├── web/                  # Web platform files
├── lib/
│   ├── main.dart         # Application entry point
│   ├── views/
│   │   ├── auth/         # Authentication pages
│   │   ├── dashboard/    # Dashboard pages
│   │   └── chat/         # Chat functionality
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── chat_service. dart
│   │   ├── notification_service.dart
│   │   └── feature_notification_service.dart
│   └── widgets/          # Reusable widgets
├── assets/
│   ├── icons/            # App icons
│   └── *. jpg, *.gif      # Pet images and media
├── pubspec.yaml          # Project dependencies
└── README.md
```

---

## 📦 Dependencies

### Core Dependencies
- **firebase_auth** - User authentication
- **cloud_firestore** - Cloud database
- **firebase_storage** - File storage
- **google_maps_flutter** - Maps integration
- **provider** - State management
- **http** - API calls

### Utility Dependencies
- **image_picker** - Image selection
- **location** - Location services
- **geolocator** - GPS location
- **permission_handler** - Runtime permissions
- **shared_preferences** - Local storage
- **intl** - Internationalization
- **uuid** - Unique identifiers

For a complete list of dependencies, see [pubspec.yaml](pubspec.yaml).

---

## 🎨 Platforms Supported

| Platform | Status |
|----------|--------|
| 🤖 Android | ✅ Supported |
| 🍎 iOS | ✅ Supported |
| 🌐 Web | ✅ Supported |
| 🪟 Windows | ✅ Supported |
| 🐧 Linux | ✅ Supported |

---

## 🔧 Configuration

### Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication (Email/Password)
3. Enable Cloud Firestore
4. Enable Firebase Storage
5. Download and add configuration files to your project

### Google Maps Setup
1. Get an API key from [Google Cloud Console](https://console.cloud.google.com)
2. Enable Maps SDK for Android, iOS, and JavaScript
3. Replace the placeholder API key in `web/index.html`

---

## 📱 Screenshots

> Add screenshots of your application here to showcase the UI/UX

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.  For major changes, please open an issue first to discuss what you would like to change.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📞 Contact

For questions or support, reach out to: 

- 📧 Email: [Contact via GitHub Issues](https://github.com/minipetorg/c-petPulse/issues)
- 📱 Phone: +94786843856

---

## 📄 License

This project does not currently have a specified license. Please contact the repository owner for usage permissions.

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Google Maps Platform for location services
- All contributors and pet lovers who support this project

---

<div align="center">

**Made with ❤️ for pets and their humans**

[Report Bug](https://github.com/minipetorg/c-petPulse/issues) · [Request Feature](https://github.com/minipetorg/c-petPulse/issues)

</div>
