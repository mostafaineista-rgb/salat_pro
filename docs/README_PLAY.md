# Play Store prep notes

## Privacy policy URL (required)

This repo includes a privacy policy page at `docs/privacy.html`.

Recommended hosting for Google Play review: **GitHub Pages**.

### Enable GitHub Pages

1. In GitHub: **Settings → Pages**
2. Source: **Deploy from a branch**
3. Branch: **main** (or master), folder: **/docs**
4. Save

Your privacy policy should then be reachable at:

- `https://mostafaineista-rgb.github.io/salat_pro/privacy.html`

This URL is referenced in-app via `lib/core/constants/brand_constants.dart` (`privacyPolicyUrl`).
Paste the same URL into Play Console → App content → Privacy policy.

