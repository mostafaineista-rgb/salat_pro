# Play Store upload checklist (Salat Pro)

## 1) Build the release bundle

Generate an Android App Bundle (AAB):

- `flutter build appbundle --release`

Output:

- `build/app/outputs/bundle/release/app-release.aab`

## 2) Turn on Play App Signing (recommended)

In Play Console:

- **Release → Setup → App integrity**
- Enable **Play App Signing**

Use your **upload key** (keystore) for uploading. Keep it private and backed up.

## 3) Upload to Internal testing first

In Play Console:

- **Release → Testing → Internal testing**
- Create a release, upload the `.aab`
- Add testers, publish to internal

Install from Play to verify real-world behavior.

## 4) Required “App content” items (acceptance-critical)

In Play Console → **Policy and programs / App content**:

- **Privacy policy**: paste the public URL used in-app (currently GitHub Pages).
- **Data safety**: declare location usage + third-party services (OSM/Overpass/Open‑Meteo).
- **Content rating**: complete questionnaire.
- **Target audience and content**: select accurately (most prayer apps: “not primarily for children” unless you intend otherwise).
- **App access**: “All features available without special access” (unless you have logins/paywalls).

## 5) Store listing essentials

Provide:

- App name, short description, full description
- Screenshots (phone at minimum; tablet optional)
- Feature graphic
- App icon (high-res)

## 6) Final pre-production sanity checks

- Location permission: only requested when needed
- Notifications: schedule + reboot behavior
- Nearby mosques: Overpass requests work on device networks
- No “install APK” flows (Play policy)

