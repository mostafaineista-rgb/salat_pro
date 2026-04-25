import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:salat_pro/l10n/app_strings.dart';
import 'package:salat_pro/providers/settings_provider.dart';

extension AppLocalization on BuildContext {
  /// Rebuilds when [SettingsProvider] language changes.
  AppStrings get strings => AppStrings.fromLanguageCode(
        Provider.of<SettingsProvider>(this, listen: true).languageCode,
      );
}
