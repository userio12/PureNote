# Release Guide — purenote v1.0.0

## Prerequisites

| Requirement | Tool/Command |
|---|---|
| Flutter SDK 3.41+ | `flutter --version` |
| Java 17 | `java --version` |
| Android SDK 34+ | `flutter doctor -v` |
| Google Play Console account | \$25 one-time registration fee |

## 1. Generate Keystore

Run this **on your machine** (never commit the keystore):

```bash
keytool -genkey -v \
  -keystore C:/Users/<you>/upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

You'll be prompted for:
- Keystore password (remember this securely)
- Key password (can be same as keystore)
- Name, org, location (any real values)

## 2. Create Signing Config File

Create `android/key.properties` (never commit this):

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=C:/Users/<you>/upload-keystore.jks
```

## 3. Register with Google Play App Signing

**Google Play will strip the upload key and resign with its own key.** This is the recommended approach.

1. Go to [Play Console](https://play.google.com/console) → Create app
2. Choose "Let Google manage and protect your app signing key (recommended)"
3. Generate the upload key certificate (next step)

```bash
keytool -export -rfc \
  -keystore C:/Users/<you>/upload-keystore.jks \
  -alias upload \
  -file upload-cert.pem
```

Upload `upload-cert.pem` when prompted in Play Console.

## 4. Build & Upload

```bash
# Clean
flutter clean && flutter pub get

# Analyze
flutter analyze

# Test
flutter test

# Build release AAB
flutter build appbundle --release --obfuscate \
  --split-debug-info=build/app/outputs/symbols

# The AAB is at:
# build/app/outputs/bundle/release/app-release.aab
```

Upload `app-release.aab` to Play Console → Internal Testing track.

Debug symbols go to `build/app/outputs/symbols/` (keep for Sentry).

## 5. Play Console Checklist

### App content
- [ ] App name: "purenote"
- [ ] Short description (80 char): "Minimal offline note-taking app. Rich text, tasks, labels, PIN lock, and backups."
- [ ] Full description (4000 char): expand on features
- [ ] Screenshots (2–8): 1080×1920 or 1080×2400 PNG
- [ ] Feature graphic: 1024×500 PNG
- [ ] Icon: 512×512 PNG (Play Store icon, can differ from app icon)

### Store listing
- [ ] App category: **Productivity**
- [ ] Tags: note-taking, notes, productivity, offline
- [ ] Content rating: **Everyone**
- [ ] Target audience: no children under 13
- [ ] Privacy policy — see below

### Data Safety
- [ ] No data collected (all local)
- [ ] No sharing with third parties
- [ ] No account or login system

### Pricing & Distribution
- [ ] Free
- [ ] Available in all countries (or select)
- [ ] No ads (enable "Contains ads" if you add any)

## 6. Privacy Policy

Since purenote has **no internet permission and collects no data**, use a minimal hosted policy:

Option A — Free hosted: Use [Privacy Policy Generator](https://privacypolicygenerator.info/) or similar.
Option B — GitHub Pages: Create a `docs/PRIVACY.md` and serve via GitHub Pages:

```md
# Privacy Policy — purenote

**Last updated:** 2026-05-29

purenote does not collect, store, or transmit any personal data.

All notes, tasks, settings, and attachments are stored locally on your device.

The app has no internet permission.

No third-party services receive data from purenote.

If you have questions, contact: your-email@example.com
```

## 7. Tag Release

```bash
git add . && git commit -m "chore: bump to v1.0.0"
git tag v1.0.0
git push && git push --tags
```

This triggers the CI workflow (`.github/workflows/flutter-release.yml`) which builds the AAB and uploads it as a GitHub Actions artifact.

## 8. Internal Testing

1. In Play Console → Release → Testing → Internal testing
2. Create a new release, upload AAB, fill in release notes
3. Add up to 100 testers via email
4. Testers install from the opt-in link
5. Smoke test on physical devices for 48h before promoting to Closed/Open track
