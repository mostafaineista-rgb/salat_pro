/// Permanent FuratByte Studio identity for Salat Pro and sibling apps.
abstract final class BrandConstants {
  static const String studioDisplayName = 'Furatbyte Studio';
  static const String shortName = 'Furatbyte';
  static const String websiteUrl = 'https://furatbyte.com';
  /// Public URL required by Google Play privacy policy field.
  ///
  /// Recommended: host via GitHub Pages (public HTTPS) for Play review.
  static const String privacyPolicyUrl =
      'https://mostafaineista-rgb.github.io/salat_pro/privacy.html';
  static const String supportEmail = 'support@furatbyte.com';
  static const String privacyEmail = 'privacy@furatbyte.com';
  static const String contactEmail = 'contact@furatbyte.com';
  static const String tagline = 'Practical, stable, user-friendly apps';
  static const String packagePrefix = 'com.furatbyte';

  static Uri get websiteUri => Uri.parse(websiteUrl);

  static Uri get privacyPolicyUri => Uri.parse(privacyPolicyUrl);

  static Uri mailtoSupportUri() => Uri(scheme: 'mailto', path: supportEmail);

  static Uri mailtoPrivacyUri() => Uri(scheme: 'mailto', path: privacyEmail);

  static Uri mailtoContactUri() => Uri(scheme: 'mailto', path: contactEmail);

  /// Settings / footers — bilingual line; pass [isEnglish] from `languageCode == 'en'`.
  static String madeByLine({required bool isEnglish}) => isEnglish
      ? 'Made by $studioDisplayName'
      : 'من تطوير $studioDisplayName';

  static String copyrightLine({required int year, required bool isEnglish}) =>
      isEnglish
          ? '© $year $studioDisplayName. All rights reserved.'
          : '© $year $studioDisplayName. جميع الحقوق محفوظة.';
}
