// Host a JSON file (HTTPS) that points to the latest build. Set a URL here to enable
// Settings → "Check for updates" and a one-time snackbar on launch when a new build is available.
//
// The app compares the remote "build" number to the package build number in pubspec (+N).
// Example (match each platform you ship):
// {
//   "version": "1.0.1",
//   "build": 2,
//   "android_apk_url": "https:// your-host /salat_pro-1.0.1.apk",
//   "windows_installer_url": "https:// your-host /salat_pro_1.0.1 Setup.exe",
//   "ios_url": "https:// apps.apple.com /app/...",
//   "release_notes": "Bug fixes and improvements"
// }
//
// Live manifest (public repo, main branch): bump `build` above pubspec +N when you ship.
// APK: attach `app-release.apk` to a GitHub Release whose tag matches the URL below.
const String kAppUpdateManifestUrl =
    'https://raw.githubusercontent.com/mostafaineista-rgb/salat_pro/main/docs/update_manifest.json';
