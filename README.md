# Firebase Auth Demo

A Flutter project demonstrating Firebase Authentication with email/password and Google Sign-In.

## Features

- User authentication with email/password
- Google Sign-In integration
- Password reset functionality
- Role-based authorization (admin access)
- Secure token storage
- Form validation
- User-friendly error handling
- Clean architecture with Provider pattern

## Setup Requirements

### 1. Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Register your app (Android and/or iOS)
3. Download the configuration files:
   - For Android: `google-services.json` (place in `android/app/`)
   - For iOS: `GoogleService-Info.plist` (place in `ios/Runner/`)

#### Security Note:
The Firebase configuration files contain API keys and should not be committed to version control.
This repository includes template files:
- `android/app/google-services.json.template`
- `ios/Runner/GoogleService-Info.plist.template`

Copy these template files, rename them to remove the `.template` extension, and add your actual Firebase credentials.

### 2. Google Sign-In Setup

1. Configure OAuth consent screen in Google Cloud Console
2. Enable Google Sign-In in Firebase Authentication settings
3. Add SHA-1 certificate fingerprint to your Firebase project for Android

### 3. Flutter Setup

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Add Google logo image:
   - Place a Google logo image in `assets/google_logo.png`

3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

- `AuthService`: Handles Firebase authentication operations
- `AuthProvider`: State management using Provider pattern
- UI Components:
  - `LoginScreen`: Email/password login and registration
  - `HomeScreen`: Authenticated user dashboard
  - `AdminPanel`: Role-restricted area

## Testing

Run tests with:
```bash
flutter test
```

## Resources

- [Firebase Authentication Documentation](https://firebase.google.com/docs/auth)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Flutter Provider Package](https://pub.dev/packages/provider)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)

## Security Best Practices

### Handling API Keys
1. Keep your `google-services.json` and `GoogleService-Info.plist` files out of version control (they're listed in .gitignore)
2. For CI/CD or team development, consider:
   - Using environment variables to inject keys during build time
   - Setting up secure credential storage in your CI system
   - Using Firebase App Distribution for testing

### Secure Data Storage
This app uses `flutter_secure_storage` for storing sensitive user data like tokens. Never store sensitive information using regular SharedPreferences or other non-encrypted storage methods.

### Additional Resource
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
