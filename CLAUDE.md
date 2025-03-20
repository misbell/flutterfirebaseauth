# Flutter Firebase Auth Project Guide

## Commands
- `flutter run` - Run the app in debug mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run a specific test file
- `flutter analyze` - Run static analysis
- `flutter pub get` - Update dependencies
- `flutter clean` - Clean build files

## Code Style Guidelines
- **Imports**: Group imports by type (dart, flutter, packages, project)
- **Formatting**: Follow flutter_lints rules in analysis_options.yaml
- **Null Safety**: Use `?` for nullable types and `!` for non-null assertions
- **Naming**: camelCase for variables/methods, PascalCase for classes
- **Error Handling**: Use try/catch blocks and rethrow when appropriate
- **State Management**: Use Provider pattern for state management
- **Comments**: Document public APIs and complex logic
- **Security**: Store sensitive data with flutter_secure_storage
- **Testing**: Write widget tests for UI components and unit tests for services