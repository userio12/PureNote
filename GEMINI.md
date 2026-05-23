# Project Overview: purenote

`purenote` is a Flutter application built with Dart. It appears to be in its early stages of development, currently based on the standard Flutter counter template.

## Tech Stack

- **Framework:** [Flutter](https://flutter.dev/)
- **Language:** [Dart](https://dart.dev/)
- **CI/CD:** GitHub Actions (for debug APK builds)
- **Styling:** Material Design (default)

## Getting Started

### Prerequisites

- Flutter SDK (version specified in `pubspec.yaml` environment: `^3.11.5`)
- Android Studio / VS Code with Flutter extensions
- Android/iOS/Web/Windows setup for development

### Key Commands

- **Install Dependencies:**
  ```bash
  flutter pub get
  ```

- **Run the Application:**
  ```bash
  flutter run
  ```

- **Build Debug APK (arm64-v8a):**
  ```bash
  flutter build apk --debug --target-platform android-arm64
  ```

- **Run Tests:**
  ```bash
  flutter test
  ```

- **Static Analysis:**
  ```bash
  flutter analyze
  ```

## Development Conventions

- **Linting:** The project uses `package:flutter_lints/flutter.yaml`. Configuration is in `analysis_options.yaml`.
- **Testing:** Widget tests are located in the `test/` directory.
- **Code Structure:**
  - `lib/main.dart`: Entry point of the application.
  - `android/`, `ios/`, `windows/`: Platform-specific configurations.
  - `.github/workflows/`: CI/CD pipeline definitions.

## Project Structure

- `lib/`: Contains the Dart source code.
- `test/`: Contains automated tests.
- `pubspec.yaml`: Project metadata and dependency management.
- `analysis_options.yaml`: Static analysis rules.
- `GEMINI.md`: This file (instructional context for Gemini CLI).
