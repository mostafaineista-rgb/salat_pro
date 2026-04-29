import 'package:flutter/material.dart';
import 'package:salat_pro/core/app_colors.dart';
import 'package:salat_pro/core/constants/brand_constants.dart';
import 'package:salat_pro/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

/// In-app privacy policy referencing FuratByte Studio contact channels.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static Future<void> _openExternal(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.strings;
    final year = DateTime.now().year;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.background, palette.surface],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: palette.textPrimary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        s.privacyPolicyTitleFull,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    Text(
                      s.privacyPolicyPublisher(BrandConstants.studioDisplayName),
                      style: TextStyle(fontSize: 15, color: palette.textPrimary, height: 1.45),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.privacyPolicyBodyLocation,
                      style: TextStyle(fontSize: 14, color: palette.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.privacyPolicyBodyNotifications,
                      style: TextStyle(fontSize: 14, color: palette.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.privacyPolicyBodyThirdPartiesTitle,
                      style: TextStyle(fontSize: 14, color: palette.textPrimary, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.privacyPolicyBodyThirdParties,
                      style: TextStyle(fontSize: 14, color: palette.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.privacyPolicyBodyDataSales,
                      style: TextStyle(fontSize: 14, color: palette.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.privacyPolicyBodyAdsAnalytics,
                      style: TextStyle(fontSize: 14, color: palette.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.privacyPolicyBodyStorage,
                      style: TextStyle(fontSize: 14, color: palette.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      s.privacyPolicyQuestionsIntro,
                      style: TextStyle(fontSize: 14, color: palette.textPrimary, height: 1.45),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _openExternal(BrandConstants.mailtoPrivacyUri()),
                      child: Text(
                        BrandConstants.privacyEmail,
                        style: TextStyle(fontSize: 14, color: palette.primary, decoration: TextDecoration.underline),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _openExternal(BrandConstants.websiteUri),
                      child: Text(
                        BrandConstants.websiteUrl,
                        style: TextStyle(fontSize: 14, color: palette.primary, decoration: TextDecoration.underline),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _openExternal(BrandConstants.privacyPolicyUri),
                      child: Text(
                        BrandConstants.privacyPolicyUrl,
                        style: TextStyle(fontSize: 12, color: palette.primary, decoration: TextDecoration.underline),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      BrandConstants.copyrightLine(year: year, isEnglish: s.isEnglish),
                      style: TextStyle(fontSize: 11, color: palette.textSecondary.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
