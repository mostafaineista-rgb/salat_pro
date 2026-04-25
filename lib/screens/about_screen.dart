import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:salat_pro/core/app_colors.dart';
import 'package:salat_pro/core/constants/brand_constants.dart';
import 'package:salat_pro/l10n/l10n.dart';
import 'package:salat_pro/screens/privacy_policy_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full About page: app version, FuratByte Studio identity, links, and support.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static Future<void> _openExternal(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.strings;
    final isEn = s.isEnglish;
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
                        s.aboutPageTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
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
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snap) {
                        final v = snap.hasData ? snap.data!.version : '—';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.aboutVersionLine(v),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.aboutPublishedBy(BrandConstants.studioDisplayName),
                              style: TextStyle(fontSize: 14, color: palette.textSecondary, height: 1.4),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      BrandConstants.tagline,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.primary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      s.aboutStudioBlurb(BrandConstants.shortName, BrandConstants.studioDisplayName),
                      style: TextStyle(fontSize: 14, color: palette.textSecondary, height: 1.45),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      s.aboutPackagePrefixLabel,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      BrandConstants.packagePrefix,
                      style: TextStyle(fontSize: 13, color: palette.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      BrandConstants.websiteUrl,
                      style: TextStyle(fontSize: 13, color: palette.primary),
                    ),
                    const SizedBox(height: 28),
                    _LinkTile(
                      icon: Icons.language_outlined,
                      title: s.labelWebsite,
                      subtitle: BrandConstants.websiteUrl,
                      onTap: () => _openExternal(BrandConstants.websiteUri),
                    ),
                    const SizedBox(height: 8),
                    _LinkTile(
                      icon: Icons.privacy_tip_outlined,
                      title: s.privacyPolicyMenu,
                      subtitle: s.privacyPolicyTileSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      s.contactSupportSection,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LinkTile(
                      icon: Icons.support_agent_outlined,
                      title: s.labelSupportEmail,
                      subtitle: BrandConstants.supportEmail,
                      onTap: () => _openExternal(BrandConstants.mailtoSupportUri()),
                    ),
                    const SizedBox(height: 8),
                    _LinkTile(
                      icon: Icons.mail_outline,
                      title: s.labelContactEmail,
                      subtitle: BrandConstants.contactEmail,
                      onTap: () => _openExternal(BrandConstants.mailtoContactUri()),
                    ),
                    const SizedBox(height: 8),
                    _LinkTile(
                      icon: Icons.shield_outlined,
                      title: s.labelPrivacyEmail,
                      subtitle: BrandConstants.privacyEmail,
                      onTap: () => _openExternal(BrandConstants.mailtoPrivacyUri()),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      BrandConstants.madeByLine(isEnglish: isEn),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: palette.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      BrandConstants.copyrightLine(year: year, isEnglish: isEn),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: palette.textSecondary.withValues(alpha: 0.85)),
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

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.primary.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Icon(icon, color: palette.primary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
