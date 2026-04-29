import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:adhan/adhan.dart';
import 'package:salat_pro/core/app_colors.dart';
import 'package:salat_pro/core/app_update_config.dart';
import 'package:salat_pro/core/constants/brand_constants.dart';
import 'package:salat_pro/screens/about_screen.dart';
import 'package:salat_pro/screens/privacy_policy_screen.dart';
import 'package:salat_pro/providers/settings_provider.dart';
import 'package:salat_pro/providers/prayer_provider.dart';

import 'package:salat_pro/services/location_service.dart';
import 'package:salat_pro/services/place_search_service.dart';
import 'package:salat_pro/l10n/app_strings.dart';
import 'package:salat_pro/l10n/l10n.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:salat_pro/services/adhan_sound_catalog.dart';
import 'package:salat_pro/services/notification_service.dart';
import 'package:salat_pro/services/app_update_service.dart';
import 'package:salat_pro/services/app_update_types.dart';
import 'package:salat_pro/utils/platform_support.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _cityController = TextEditingController();
  final FocusNode _manualFocus = FocusNode();
  bool _isSearching = false;
  Timer? _placeDebounce;
  List<PlaceSearchResult> _placeSuggestions = [];
  bool _placeSearchLoading = false;
  bool _checkingForUpdate = false;
  late final Future<List<AdhanSoundOption>> _adhanOptionsFuture = AdhanSoundCatalog.discover();
  late final Future<PackageInfo> _packageInfoFuture = PackageInfo.fromPlatform();

  /// Active preview player so we can stop it when the user switches selection, taps
  /// stop, or navigates away.
  AudioPlayer? _previewPlayer;
  String? _previewingAssetKey;

  @override
  void dispose() {
    _placeDebounce?.cancel();
    _cityController.dispose();
    _manualFocus.dispose();
    _previewPlayer?.dispose();
    super.dispose();
  }

  Future<void> _startPreview(String? assetKey) async {
    await _previewPlayer?.stop();
    await _previewPlayer?.dispose();
    final player = await NotificationService.previewAdhan(
      adhanAssetKey: assetKey,
      onDone: () {
        if (!mounted) return;
        setState(() {
          _previewPlayer?.dispose();
          _previewPlayer = null;
          _previewingAssetKey = null;
        });
      },
    );
    if (!mounted) {
      await player.stop();
      await player.dispose();
      return;
    }
    setState(() {
      _previewPlayer = player;
      _previewingAssetKey = assetKey;
    });
  }

  Future<void> _stopPreview() async {
    await _previewPlayer?.stop();
    await _previewPlayer?.dispose();
    if (!mounted) return;
    setState(() {
      _previewPlayer = null;
      _previewingAssetKey = null;
    });
  }

  Future<void> _openBrandUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  /// Shows a precise explanation for every non-success [outcome] so silent OS-level
  /// notification blocks (Android 13+ POST_NOTIFICATIONS, channel silenced in shade)
  /// stop looking like an app bug. Success cases fall through to a short snackbar.
  Future<void> _handleTestOutcome(
    BuildContext context,
    AppStrings s,
    TestNotificationOutcome outcome, {
    int? scheduledSeconds,
  }) async {
    String? title;
    String? body;
    bool showOpenSettings = false;

    switch (outcome) {
      case TestNotificationOutcome.delivered:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.notifyOutcomeDeliveredBody)),
        );
        return;
      case TestNotificationOutcome.scheduled:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.notifyOutcomeScheduledBody(scheduledSeconds ?? 15))),
        );
        return;
      case TestNotificationOutcome.permissionDenied:
        title = s.notifyOutcomePermissionTitle;
        body = s.notifyOutcomePermissionBody;
        showOpenSettings = true;
        break;
      case TestNotificationOutcome.permissionPermanentlyDenied:
        title = s.notifyOutcomePermissionTitle;
        body = s.notifyOutcomePermissionPermanentBody;
        showOpenSettings = true;
        break;
      case TestNotificationOutcome.appNotificationsDisabled:
        title = s.notifyOutcomeAppDisabledTitle;
        body = s.notifyOutcomeAppDisabledBody;
        showOpenSettings = true;
        break;
      case TestNotificationOutcome.channelBlocked:
        title = s.notifyOutcomeChannelBlockedTitle;
        body = s.notifyOutcomeChannelBlockedBody;
        showOpenSettings = true;
        break;
      case TestNotificationOutcome.deliveryFailed:
        title = s.notifyOutcomeDeliveryFailedTitle;
        body = s.notifyOutcomeDeliveryFailedBody;
        break;
      case TestNotificationOutcome.unsupported:
        return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final err = NotificationService.lastNativePostError;
        final detail = (err != null && err.length > 500) ? '${err.substring(0, 500)}…' : err;
        final content = outcome == TestNotificationOutcome.deliveryFailed && detail != null
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(body!),
                    const SizedBox(height: 12),
                    SelectableText(detail, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              )
            : Text(body!);
        return AlertDialog(
          title: Text(title!),
          content: content,
          actions: [
            if (showOpenSettings)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  NotificationService.openSystemAppSettings();
                },
                child: Text(s.openAppSettingsLabel),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(s.okLabel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onCheckForUpdates(AppStrings s) async {
    if (kIsWeb) return;
    if (kAppUpdateManifestUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.updateManifestUnconfigured)),
      );
      return;
    }
    setState(() => _checkingForUpdate = true);
    try {
      final st = await AppUpdateService.check();
      if (!mounted) return;
      if (!st.hasUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.updateOnLatest)),
        );
        return;
      }
      if (st.remote == null) return;
      final remote = st.remote!;
      final isIos = defaultTargetPlatform == TargetPlatform.iOS;
      final isAndroid = defaultTargetPlatform == TargetPlatform.android;
      final isWindows = defaultTargetPlatform == TargetPlatform.windows;
      final notes = remote.releaseNotes;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(s.updateNewVersionTitle(remote.version)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notes != null && notes.isNotEmpty) Text(notes),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(s.updateLater),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  unawaited(_runInstallWithProgress(s, remote));
                },
                child: Text(
                  isAndroid
                      ? s.updateOpenPlayStore
                      : isIos
                          ? s.updateOpenInBrowser
                          : isWindows
                              ? s.updateDownloadInstall
                              : s.updateOpenInBrowser,
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.updateError}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _checkingForUpdate = false);
      }
    }
  }

  Future<void> _runInstallWithProgress(AppStrings s, UpdateManifest m) async {
    final isWindows = defaultTargetPlatform == TargetPlatform.windows;
    if (!isWindows) {
      // Android opens Play Store; iOS opens App Store / browser. No download progress needed.
      await AppUpdateService.installLatest(m);
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              Expanded(child: Text(s.updateDownloading)),
            ],
          ),
        ),
      ),
    );
    try {
      await AppUpdateService.installLatest(m);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
      return;
    }
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _onManualQueryChanged(SettingsProvider settings, String text) {
    _placeDebounce?.cancel();
    final q = text.trim();
    if (q.length < PlaceSearchService.minQueryLength) {
      setState(() {
        _placeSuggestions = [];
        _placeSearchLoading = false;
      });
      return;
    }
    setState(() => _placeSearchLoading = true);
    _placeDebounce = Timer(const Duration(milliseconds: 450), () async {
      final results = await PlaceSearchService.search(q);
      if (!mounted) return;
      setState(() {
        _placeSuggestions = results;
        _placeSearchLoading = false;
      });
    });
  }

  void _applyPlaceSuggestion(SettingsProvider settings, PlaceSearchResult r, AppStrings strings) {
    settings.setManualLocation(r.displayName, r.latitude, r.longitude);
    _cityController.clear();
    _manualFocus.unfocus();
    setState(() {
      _placeSuggestions = [];
      _placeSearchLoading = false;
    });
    context.read<PrayerProvider>().refreshPrayerTimes(settings);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.snackLocationShort(r.displayName.split(',').first.trim()))),
    );
  }

  Future<void> _handleManualSearch(SettingsProvider settings, AppStrings strings) async {
    final city = _cityController.text.trim();
    if (city.isEmpty) return;

    setState(() => _isSearching = true);
    
    try {
      final coords = await LocationService.getCoordinatesFromAddress(city);
      if (coords != null) {
        final lat = coords['latitude']!;
        final lon = coords['longitude']!;
        final label = await LocationService.getCityName(lat, lon) ?? city;
        settings.setManualLocation(label, lat, lon);
        if (mounted) {
          context.read<PrayerProvider>().refreshPrayerTimes(settings);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.locationSetTo(label.split(',').first.trim()))),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.locationNotFound)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final palette = context.palette;
    final s = context.strings;

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
            children: [
              _buildHeader(context, s),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildSectionHeader(context, s.sectionLocation),
                    _buildLocationCard(context, settings, s),
                    const SizedBox(height: 16),
                    _buildToggleCard(
                      context,
                      s.manualLocation,
                      s.manualLocationSubtitle,
                      settings.useManualLocation,
                      (val) {
                        settings.setUseManualLocation(val);
                        context.read<PrayerProvider>().refreshPrayerTimes(settings);
                      },
                    ),
                    if (settings.useManualLocation) ...[
                      const SizedBox(height: 16),
                      _buildManualSearchField(context, settings, s),
                    ],
                    if (supportsAdhanSettingsUi) ...[
                      const SizedBox(height: 32),
                      _buildSectionHeader(context, s.sectionAdhan),
                      if (kIsWeb) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                          child: Text(
                            s.adhanSoundWebNote,
                            style: TextStyle(
                              color: context.palette.textSecondary.withValues(alpha: 0.9),
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      FutureBuilder<List<AdhanSoundOption>>(
                        future: _adhanOptionsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildAdhanSoundPlaceholderCard(
                                  context,
                                  s,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                          if (snapshot.hasError) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildAdhanSoundPlaceholderCard(
                                  context,
                                  s,
                                  child: Text(
                                    '${s.adhanSoundLoadError} (${snapshot.error})',
                                    style: TextStyle(
                                      color: context.palette.textSecondary,
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                          final options = snapshot.data ?? [];
                          if (options.isEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildAdhanSoundPlaceholderCard(
                                  context,
                                  s,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.adhanSoundEmpty,
                                        style: TextStyle(
                                          color: context.palette.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        s.adhanSoundEmptyHint,
                                        style: TextStyle(
                                          color: context.palette.textSecondary.withValues(alpha: 0.9),
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildAdhanSoundCard(context, settings, s, options),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    ],
                    if (supportsPrayerNotifications) ...[
                      _buildNotificationTestCard(context, settings, s),
                    ],
                    const SizedBox(height: 32),
                    _buildSectionHeader(context, s.sectionPrayerCalc),
                    _buildMethodSelector(context, settings, s),
                    const SizedBox(height: 32),
                    _buildSectionHeader(context, s.sectionAppPrefs),
                    _buildLanguageCard(context, settings, s),
                    const SizedBox(height: 16),
                    _buildThemePreferenceCard(context, settings, s),
                    const SizedBox(height: 16),
                    _buildClockFormatCard(context, settings, s),
                    if (!kIsWeb && kAppUpdateManifestUrl.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildSectionHeader(context, s.sectionAppUpdate),
                      const SizedBox(height: 12),
                      _buildAppUpdateCard(context, s),
                    ],
                    if (!kIsWeb &&
                        (defaultTargetPlatform == TargetPlatform.android ||
                            defaultTargetPlatform == TargetPlatform.iOS)) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, s.sectionPermissions),
                      const SizedBox(height: 12),
                      _buildOpenSystemSettingsCard(context, s),
                    ],
                    const SizedBox(height: 48),
                    _buildBrandFooter(context, s),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppStrings s) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Text(
            s.settingsTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, SettingsProvider settings, AppStrings s) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.languageLabel,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'ar',
                label: Text(s.languageArabic, style: TextStyle(color: palette.textPrimary, fontSize: 13)),
              ),
              ButtonSegment(
                value: 'en',
                label: Text(s.languageEnglish, style: TextStyle(color: palette.textPrimary, fontSize: 13)),
              ),
            ],
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              side: WidgetStateProperty.all(BorderSide(color: palette.strokeVerySubtle)),
            ),
            selected: {settings.languageCode},
            onSelectionChanged: (next) {
              if (next.isEmpty) return;
              settings.setLanguageCode(next.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemePreferenceCard(BuildContext context, SettingsProvider settings, AppStrings s) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.appearance,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.appearanceSubtitle,
            style: TextStyle(color: palette.textSecondary.withValues(alpha: 0.9), fontSize: 12),
          ),
          const SizedBox(height: 14),
          SegmentedButton<AppThemePreference>(
            segments: [
              ButtonSegment(
                value: AppThemePreference.system,
                label: Text(s.themeAuto, style: TextStyle(color: palette.textPrimary, fontSize: 12)),
                icon: Icon(Icons.brightness_auto_rounded, size: 18, color: palette.primary),
              ),
              ButtonSegment(
                value: AppThemePreference.light,
                label: Text(s.themeLight, style: TextStyle(color: palette.textPrimary, fontSize: 12)),
                icon: Icon(Icons.light_mode_rounded, size: 18, color: palette.primary),
              ),
              ButtonSegment(
                value: AppThemePreference.dark,
                label: Text(s.themeDark, style: TextStyle(color: palette.textPrimary, fontSize: 12)),
                icon: Icon(Icons.dark_mode_rounded, size: 18, color: palette.primary),
              ),
            ],
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              side: WidgetStateProperty.all(BorderSide(color: palette.strokeVerySubtle)),
            ),
            selected: {settings.themePreference},
            onSelectionChanged: (next) {
              if (next.isEmpty) return;
              settings.setThemePreference(next.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClockFormatCard(BuildContext context, SettingsProvider settings, AppStrings s) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.clockFormatLabel,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.clockFormatSubtitle,
            style: TextStyle(color: palette.textSecondary.withValues(alpha: 0.9), fontSize: 12),
          ),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text(s.clockFormat12, style: TextStyle(color: palette.textPrimary, fontSize: 13)),
              ),
              ButtonSegment(
                value: true,
                label: Text(s.clockFormat24, style: TextStyle(color: palette.textPrimary, fontSize: 13)),
              ),
            ],
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              side: WidgetStateProperty.all(BorderSide(color: palette.strokeVerySubtle)),
            ),
            selected: {settings.use24HourClock},
            onSelectionChanged: (next) {
              if (next.isEmpty) return;
              settings.setUse24HourClock(next.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: palette.primary,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, SettingsProvider settings, AppStrings s) {
    final palette = context.palette;
    final cityLabel =
        settings.city == 'Detecting...' ? s.detectingCity : settings.city;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.primary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: palette.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.useManualLocation ? s.manualCity : s.currentCity,
                  style: TextStyle(color: palette.textSecondary, fontSize: 13),
                ),
                Text(
                  cityLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (!settings.useManualLocation)
            TextButton(
              onPressed: () {
                context.read<PrayerProvider>().refreshPrayerTimes(settings);
              },
              child: Text(s.detect, style: TextStyle(color: palette.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildManualSearchField(BuildContext context, SettingsProvider settings, AppStrings s) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityController,
                  focusNode: _manualFocus,
                  style: TextStyle(color: palette.textPrimary),
                  decoration: InputDecoration(
                    hintText: s.searchCityHint,
                    hintStyle: TextStyle(color: palette.textSecondary, fontSize: 14),
                    border: InputBorder.none,
                  ),
                  onChanged: (t) => _onManualQueryChanged(settings, t),
                  onSubmitted: (_) => _handleManualSearch(settings, s),
                ),
              ),
              if (_isSearching || _placeSearchLoading)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: CircularProgressIndicator(strokeWidth: 2, color: palette.primary),
                  ),
                )
              else
                IconButton(
                  icon: Icon(Icons.search, color: palette.primary),
                  onPressed: () => _handleManualSearch(settings, s),
                ),
            ],
          ),
        ),
        if (_placeSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Material(
            color: palette.surfaceHigh,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _placeSuggestions.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: palette.strokeVerySubtle),
                itemBuilder: (ctx, i) {
                  final r = _placeSuggestions[i];
                  final short = r.displayName.length > 80 ? '${r.displayName.substring(0, 80)}…' : r.displayName;
                  return ListTile(
                    dense: true,
                    title: Text(
                      short,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.textPrimary, fontSize: 13),
                    ),
                    leading: Icon(Icons.place_outlined, color: palette.primary, size: 22),
                    onTap: () => _applyPlaceSuggestion(settings, r, s),
                  );
                },
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          s.osmHint,
          style: TextStyle(color: palette.textSecondary.withValues(alpha: 0.85), fontSize: 11, height: 1.3),
        ),
      ],
    );
  }

  /// Same chrome as [_buildAdhanSoundCard] for loading / empty / error states.
  Widget _buildAdhanSoundPlaceholderCard(
    BuildContext context,
    AppStrings s, {
    required Widget child,
  }) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.adhanSoundTitle,
            style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            s.adhanSoundSubtitle,
            style: TextStyle(color: palette.textSecondary.withValues(alpha: 0.9), fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildAdhanSoundCard(
    BuildContext context,
    SettingsProvider settings,
    AppStrings s,
    List<AdhanSoundOption> options,
  ) {
    final palette = context.palette;
    final current = settings.adhanAssetPath;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.adhanSoundTitle,
            style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            s.adhanSoundSubtitle,
            style: TextStyle(color: palette.textSecondary.withValues(alpha: 0.9), fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: palette.surfaceHigh,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.strokeVerySubtle),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(14),
                    dropdownColor: palette.surfaceHigh,
                    style: TextStyle(color: palette.textPrimary, fontSize: 14),
                    value: current != null && options.any((o) => o.assetKey == current) ? current : options.first.assetKey,
                    items: options
                        .map(
                          (o) => DropdownMenuItem<String>(
                            value: o.assetKey,
                            child: Text(o.displayTitle, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (key) async {
                      if (key == null) return;
                      await _stopPreview();
                      await settings.setAdhanAssetPath(key);
                      if (!context.mounted) return;
                      context.read<PrayerProvider>().updateWithSettings(settings);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildPreviewButton(
                context,
                s,
                palette,
                assetKey: settings.adhanAssetPath ?? options.first.assetKey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewButton(
    BuildContext context,
    AppStrings s,
    AppPalette palette, {
    required String assetKey,
  }) {
    final isPlaying = _previewPlayer != null && _previewingAssetKey == assetKey;
    return Material(
      color: isPlaying ? palette.primary : palette.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.strokeVerySubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          if (isPlaying) {
            await _stopPreview();
          } else {
            await _startPreview(assetKey);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Tooltip(
            message: isPlaying ? s.adhanPreviewStopTooltip : s.adhanPreviewTooltip,
            child: Icon(
              isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: isPlaying ? palette.onPrimary : palette.textPrimary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTestCard(BuildContext context, SettingsProvider settings, AppStrings s) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.testAdhanTitle,
            style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            s.testAdhanBody,
            style: TextStyle(color: palette.textSecondary.withValues(alpha: 0.9), fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  final outcome = await NotificationService.showTestPrayerNotificationNow(
                    languageCode: settings.languageCode,
                    adhanAssetKey: settings.adhanAssetPath,
                  );
                  if (!context.mounted) return;
                  await _handleTestOutcome(context, s, outcome);
                },
                icon: const Icon(Icons.notifications_active_outlined, size: 20),
                label: Text(s.testNow),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final outcome = await NotificationService.scheduleTestPrayerNotification(
                    delay: const Duration(seconds: 15),
                    languageCode: settings.languageCode,
                    adhanAssetKey: settings.adhanAssetPath,
                  );
                  if (!context.mounted) return;
                  await _handleTestOutcome(context, s, outcome, scheduledSeconds: 15);
                },
                icon: const Icon(Icons.schedule, size: 20),
                label: Text(s.testIn15s),
                style: OutlinedButton.styleFrom(foregroundColor: palette.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector(BuildContext context, SettingsProvider settings, AppStrings s) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildMethodItem(
            context,
            s.methodMwl,
            CalculationMethod.muslim_world_league,
            settings,
          ),
          Divider(height: 1, color: palette.strokeVerySubtle),
          _buildMethodItem(
            context,
            s.methodIsna,
            CalculationMethod.north_america,
            settings,
          ),
          Divider(height: 1, color: palette.strokeVerySubtle),
          _buildMethodItem(
            context,
            s.methodEgypt,
            CalculationMethod.egyptian,
            settings,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodItem(
    BuildContext context,
    String name,
    CalculationMethod method,
    SettingsProvider settings,
  ) {
    final palette = context.palette;
    final isSelected = settings.method == method;
    return ListTile(
      title: Text(
        name,
        style: TextStyle(
          color: isSelected ? palette.primary : palette.textPrimary,
          fontSize: 14,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: palette.primary) : null,
      onTap: () {
        settings.setMethod(method);
        context.read<PrayerProvider>().refreshPrayerTimes(settings);
      },
    );
  }

  Widget _buildToggleCard(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.primary.withValues(alpha: 0.05)),
      ),
      child: SwitchListTile(
        title: Text(title, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: palette.textSecondary, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: palette.primary,
        activeTrackColor: palette.primary.withValues(alpha: 0.5),
        inactiveThumbColor: palette.textSecondary,
      ),
    );
  }

  Widget _buildAppUpdateCard(BuildContext context, AppStrings s) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _checkingForUpdate ? null : () => unawaited(_onCheckForUpdates(s)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.primary.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(Icons.system_update_outlined, color: palette.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.checkForUpdates,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.checkForUpdatesSubtitle,
                      style: TextStyle(fontSize: 12, color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              if (_checkingForUpdate)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right, size: 22, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpenSystemSettingsCard(BuildContext context, AppStrings s) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => openAppSettings(),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.primary.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(Icons.settings_applications_outlined, color: palette.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.openSystemSettings,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.openSystemSettingsSubtitle,
                      style: TextStyle(fontSize: 12, color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, size: 18, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandFooter(BuildContext context, AppStrings s) {
    final palette = context.palette;
    final isEn = s.isEnglish;
    final year = DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(context, s.sectionAboutBrand),
        const SizedBox(height: 4),
        _buildBrandNavCard(
          context,
          icon: Icons.info_outline,
          title: s.aboutPageTitle,
          subtitle: BrandConstants.tagline,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildBrandNavCard(
          context,
          icon: Icons.privacy_tip_outlined,
          title: s.privacyPolicyMenu,
          subtitle: s.privacyPolicyTileSubtitle,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyScreen()),
            );
          },
        ),
        const SizedBox(height: 28),
        _buildSectionHeader(context, s.contactSupportSection),
        const SizedBox(height: 12),
        _buildBrandNavCard(
          context,
          icon: Icons.language_outlined,
          title: s.labelWebsite,
          subtitle: BrandConstants.websiteUrl,
          onTap: () => _openBrandUri(BrandConstants.websiteUri),
        ),
        const SizedBox(height: 12),
        _buildBrandNavCard(
          context,
          icon: Icons.support_agent_outlined,
          title: s.labelSupportEmail,
          subtitle: BrandConstants.supportEmail,
          onTap: () => _openBrandUri(BrandConstants.mailtoSupportUri()),
        ),
        const SizedBox(height: 12),
        _buildBrandNavCard(
          context,
          icon: Icons.mail_outline,
          title: s.labelContactEmail,
          subtitle: BrandConstants.contactEmail,
          onTap: () => _openBrandUri(BrandConstants.mailtoContactUri()),
        ),
        const SizedBox(height: 12),
        _buildBrandNavCard(
          context,
          icon: Icons.shield_outlined,
          title: s.labelPrivacyEmail,
          subtitle: BrandConstants.privacyEmail,
          onTap: () => _openBrandUri(BrandConstants.mailtoPrivacyUri()),
        ),
        const SizedBox(height: 28),
        FutureBuilder<PackageInfo>(
          future: _packageInfoFuture,
          builder: (context, snap) {
            final v = snap.hasData ? snap.data!.version : '—';
            return Text(
              s.aboutVersionLine(v),
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          BrandConstants.tagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.primary.withValues(alpha: 0.55),
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          BrandConstants.madeByLine(isEnglish: isEn),
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          BrandConstants.copyrightLine(year: year, isEnglish: isEn),
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textSecondary.withValues(alpha: 0.85), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBrandNavCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.primary.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(icon, color: palette.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
              Icon(Icons.chevron_right, size: 22, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

