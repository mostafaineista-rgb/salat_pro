import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:salat_pro/l10n/app_strings.dart';
import 'package:salat_pro/services/adhan_service.dart';
import 'package:salat_pro/services/adhan_sound_catalog.dart';
import 'package:salat_pro/utils/platform_support.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Converts a [DateTime] (any zone) to a [tz.TZDateTime] that represents the
/// same instant. Avoids relying on [tz.local], which is unset unless the app
/// configures a timezone database location.
tz.TZDateTime _tzAtSameInstant(DateTime when) {
  return tz.TZDateTime.fromMillisecondsSinceEpoch(
    tz.UTC,
    when.millisecondsSinceEpoch,
  );
}

/// Result of a notification test so the UI can show a precise explanation when
/// delivery fails instead of a silent "nothing happened".
enum TestNotificationOutcome {
  unsupported,
  permissionDenied,
  permissionPermanentlyDenied,
  appNotificationsDisabled,
  channelBlocked,
  delivered,
  scheduled,
  deliveryFailed,
}

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  /// Filled when [showTestPrayerNotificationNow] / [scheduleTestPrayerNotification] catch
  /// a platform exception (shown in the settings dialog for diagnosis).
  static String? lastNativePostError;

  /// Must match `applicationId` in `android/app/build.gradle`.
  static const String _androidApplicationId = 'com.salatpro.salat_pro';

  /// Default Android raw resource name (`res/raw/adhan.mp3`) shipped in-repo.
  static const String _androidDefaultRawName = 'adhan';

  /// How long the prayer notification stays on Android (shade + status bar).
  static int _adhanHoldMs = 10 * 60 * 1000;

  /// Channel id is versioned: if the sound selection changes, we create a new channel id
  /// because Android caches channel sound per id (you cannot edit a channel's sound).
  static String _androidChannelId = 'prayer_alerts_alarm_adhan';

  static const List<Prayer> _scheduledPrayers = [
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  static final Int64List _vibrationPattern = Int64List.fromList([
    0,
    500,
    200,
    500,
    200,
    500,
    200,
    800,
  ]);

  /// Android: raw resource name currently used for the Adhan sound.
  static String _androidRawName = _androidDefaultRawName;

  /// iOS: file name inside app bundle or `Library/Sounds/`.
  static String _iosNotificationSoundFile = 'adhan.mp3';

  static AndroidNotificationSound get _androidSound =>
      RawResourceAndroidNotificationSound(_androidRawName);

  /// Shared builder. [ongoing] is off for tests so Samsung/OneUI doesn't mute them
  /// (ongoing notifications on alarm-category channels are silenced on several OEMs).
  static NotificationDetails _prayerNotificationDetails(
    AppStrings strings, {
    bool ongoing = true,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        strings.channelPrayerAlerts,
        channelDescription: strings.channelPrayerAlertsDesc,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        playSound: true,
        sound: _androidSound,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        onlyAlertOnce: false,
        ongoing: ongoing,
        autoCancel: !ongoing,
        timeoutAfter: _adhanHoldMs,
        visibility: NotificationVisibility.public,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
        sound: _iosNotificationSoundFile,
        interruptionLevel: InterruptionLevel.active,
      ),
    );
  }

  static Future<void> _deleteAndroidChannel(String channelId) async {
    if (!supportsPrayerNotifications) return;
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try {
      await android?.deleteNotificationChannel(channelId);
    } catch (e) {
      debugPrint('NotificationService: deleteNotificationChannel($channelId) threw $e');
    }
  }

  /// Deletes stale channels created by older builds (e.g. `salih_mahmood`) so the user
  /// doesn't end up with a long list of dead channels in the system notification settings.
  static Future<void> _purgeLegacyChannels() async {
    if (!supportsPrayerNotifications) return;
    const legacyIds = <String>[
      'prayer_alerts',
      'prayer_alerts_alarm',
      'prayer_alerts_alarm_adhan_fallback',
    ];
    for (final id in legacyIds) {
      await _deleteAndroidChannel(id);
    }
  }

  static Future<void> _ensureAndroidAlarmChannel(String languageCode) async {
    if (!supportsPrayerNotifications) return;
    final strings = AppStrings.fromLanguageCode(languageCode);
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    // Android caches the sound set on a channel, so creating the channel again with a new
    // sound is silently ignored. Deleting + recreating is the only way to force the new
    // sound — safe to call even if the channel doesn't yet exist.
    await _deleteAndroidChannel(_androidChannelId);
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _androidChannelId,
        strings.channelPrayerAlerts,
        description: strings.channelPrayerAlertsDescShort,
        importance: Importance.max,
        playSound: true,
        sound: _androidSound,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
    debugPrint(
      'NotificationService: channel="$_androidChannelId" sound=android.resource://$_androidApplicationId/raw/$_androidRawName',
    );
  }

  /// iOS still uses a runtime asset copy because `DarwinNotificationDetails.sound` accepts
  /// any file name under the app bundle or `Library/Sounds/`.
  static Future<String?> _copyAssetToLibrarySounds(String assetKey) async {
    final data = await rootBundle.load(assetKey);
    final libDir = await getLibraryDirectory();
    final soundsDir = Directory(p.join(libDir.path, 'Sounds'));
    await soundsDir.create(recursive: true);
    final ext = p.extension(assetKey).toLowerCase();
    final dest = File(p.join(soundsDir.path, 'salat_pro_adhan$ext'));
    await dest.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return p.basename(dest.path);
  }

  /// Wires the selected adhan clip so [AndroidNotificationDetails.sound] /
  /// [DarwinNotificationDetails.sound] resolve correctly. Falls back to the bundled
  /// defaults (`res/raw/adhan` on Android, `adhan.mp3` on iOS) when no match is found.
  static Future<void> prepareAdhanForNotifications({
    required String languageCode,
    String? selectedAssetKey,
  }) async {
    if (!supportsPrayerNotifications) return;

    final options = await AdhanSoundCatalog.discover();
    final resolved = options.any((o) => o.assetKey == selectedAssetKey)
        ? options.firstWhere((o) => o.assetKey == selectedAssetKey)
        : (options.isNotEmpty ? options.first : null);

    if (defaultTargetPlatform == TargetPlatform.android) {
      final name = resolved?.rawResourceName ?? _androidDefaultRawName;
      _androidRawName = name;
      // Channel sound can only change via a new channel id (channels are sticky).
      _androidChannelId = 'prayer_alerts_alarm_$name';
      await _purgeLegacyChannels();
      await refreshAdhanHoldDuration();
      await _ensureAndroidAlarmChannel(languageCode);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (resolved != null) {
        final name = await _copyAssetToLibrarySounds(resolved.assetKey);
        if (name != null) {
          _iosNotificationSoundFile = name;
        }
      } else {
        _iosNotificationSoundFile = 'adhan.mp3';
      }
    }
  }

  /// Reads duration of the active Adhan clip so notification [timeoutAfter] matches the file.
  static Future<void> refreshAdhanHoldDuration() async {
    if (!supportsPrayerNotifications || defaultTargetPlatform != TargetPlatform.android) return;
    final player = AudioPlayer();
    try {
      await player.setSource(
        UrlSource('android.resource://$_androidApplicationId/raw/$_androidRawName'),
      );
      Duration? d = await player.getDuration();
      if (d == null || d.inMilliseconds <= 0) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        d = await player.getDuration();
      }
      if (d != null && d.inMilliseconds > 0) {
        const trailingBufferMs = 8000;
        _adhanHoldMs = min(d.inMilliseconds + trailingBufferMs, 30 * 60 * 1000);
        debugPrint('NotificationService: adhan duration ${_adhanHoldMs}ms hold ($_androidRawName)');
      }
    } catch (e, st) {
      debugPrint('NotificationService: could not read adhan duration ($_androidRawName), using default hold: $e\n$st');
    } finally {
      await player.dispose();
    }
  }

  static Future<void> init() async {
    if (!supportsPrayerNotifications) return;
    tz.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _notifications.initialize(settings);
  }

  /// Clears scheduled prayer + test alerts without [cancelAll] on Android (avoids Gson/R8 issues in release).
  static Future<void> _clearPendingPrayerNotifications() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      const testIds = <int>[9100001, 9100002];
      for (final id in testIds) {
        await _notifications.cancel(id);
      }
      for (var id = 0; id < 500; id++) {
        await _notifications.cancel(id);
      }
      return;
    }
    await _notifications.cancelAll();
  }

  /// Schedules the next [daysAhead] calendar days of prayer alerts (today at local midnight + offset).
  static Future<void> schedulePrayerNotifications(
    Position position,
    CalculationMethod method, {
    required String languageCode,
    String? adhanAssetKey,
    int daysAhead = 7,
  }) async {
    if (!supportsPrayerNotifications) return;
    await prepareAdhanForNotifications(languageCode: languageCode, selectedAssetKey: adhanAssetKey);
    await _clearPendingPrayerNotifications();

    final strings = AppStrings.fromLanguageCode(languageCode);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final details = _prayerNotificationDetails(strings);

    for (var day = 0; day < daysAhead; day++) {
      final date = today.add(Duration(days: day));
      final times = AdhanService.getPrayerTimesForDate(position, method, date);

      for (var i = 0; i < _scheduledPrayers.length; i++) {
        final prayer = _scheduledPrayers[i];
        final time = _timeForPrayer(times, prayer);
        if (time.isAfter(now)) {
          final id = day * 10 + i;
          final label = strings.prayerName(prayer);
          await _notifications.zonedSchedule(
            id,
            strings.timeForPrayer(label),
            strings.notificationBody,
            _tzAtSameInstant(time),
            details,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }
    }
  }

  static DateTime _timeForPrayer(PrayerTimes times, Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return times.fajr;
      case Prayer.sunrise:
        return times.sunrise;
      case Prayer.dhuhr:
        return times.dhuhr;
      case Prayer.asr:
        return times.asr;
      case Prayer.maghrib:
        return times.maghrib;
      case Prayer.isha:
        return times.isha;
      case Prayer.none:
        return times.fajr;
    }
  }

  /// Runs every precondition the system uses to silently drop notifications.
  /// Returning an outcome lets the UI explain exactly what the user must toggle —
  /// silent failure on Android 13+ is usually POST_NOTIFICATIONS or app-level disable.
  static Future<TestNotificationOutcome> _verifyAndroidCanNotify() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return TestNotificationOutcome.delivered; // iOS handled by its own init prompt.
    }
    var perm = await Permission.notification.status;
    if (perm.isDenied) {
      perm = await Permission.notification.request();
    }
    if (!perm.isGranted) {
      return perm.isPermanentlyDenied
          ? TestNotificationOutcome.permissionPermanentlyDenied
          : TestNotificationOutcome.permissionDenied;
    }
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final enabled = await android?.areNotificationsEnabled() ?? true;
    if (!enabled) return TestNotificationOutcome.appNotificationsDisabled;
    return TestNotificationOutcome.delivered;
  }

  /// Opens the system settings page for this app so the user can re-enable the
  /// notification permission or un-silence the app channel.
  static Future<void> openSystemAppSettings() async {
    await openAppSettings();
  }

  /// Immediate test: adhan sound + vibration. Non-ongoing so Samsung/OneUI doesn't
  /// suppress the sound it associates with pinned alarm-category notifications.
  static Future<TestNotificationOutcome> showTestPrayerNotificationNow({
    String languageCode = 'ar',
    String? adhanAssetKey,
  }) async {
    if (!supportsPrayerNotifications) return TestNotificationOutcome.unsupported;
    final pre = await _verifyAndroidCanNotify();
    if (pre != TestNotificationOutcome.delivered) return pre;

    await prepareAdhanForNotifications(languageCode: languageCode, selectedAssetKey: adhanAssetKey);
    final strings = AppStrings.fromLanguageCode(languageCode);
    const id = 9100001;
    lastNativePostError = null;
    try {
      await _notifications.show(
        id,
        strings.adhanTestTitle,
        strings.adhanTestBody,
        _prayerNotificationDetails(strings, ongoing: false),
      );
    } catch (e, st) {
      lastNativePostError = e.toString();
      debugPrint('NotificationService: show() failed: $e\n$st');
      return TestNotificationOutcome.deliveryFailed;
    }
    // Give the system a moment to land the notification, then confirm delivery.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (defaultTargetPlatform == TargetPlatform.android) {
      final active = await _notifications.getActiveNotifications();
      final delivered = active.any((a) => a.id == id);
      if (!delivered) {
        debugPrint('NotificationService: show($id) returned but no active notification visible — likely channel-level block');
        return TestNotificationOutcome.channelBlocked;
      }
    }
    return TestNotificationOutcome.delivered;
  }

  /// Scheduled test (default 15s) — uses the same channel as real prayer alerts.
  static Future<TestNotificationOutcome> scheduleTestPrayerNotification({
    Duration delay = const Duration(seconds: 15),
    String languageCode = 'ar',
    String? adhanAssetKey,
  }) async {
    if (!supportsPrayerNotifications) return TestNotificationOutcome.unsupported;
    final pre = await _verifyAndroidCanNotify();
    if (pre != TestNotificationOutcome.delivered) return pre;

    await prepareAdhanForNotifications(languageCode: languageCode, selectedAssetKey: adhanAssetKey);
    final strings = AppStrings.fromLanguageCode(languageCode);
    final when = _tzAtSameInstant(DateTime.now().add(delay));
    lastNativePostError = null;
    try {
      await _notifications.zonedSchedule(
        9100002,
        strings.adhanTestScheduledTitle,
        strings.adhanTestScheduledBody,
        when,
        _prayerNotificationDetails(strings, ongoing: false),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e, st) {
      lastNativePostError = e.toString();
      debugPrint('NotificationService: zonedSchedule failed: $e\n$st');
      return TestNotificationOutcome.deliveryFailed;
    }
    return TestNotificationOutcome.scheduled;
  }

  /// Plays the selected adhan clip in-app so users can confirm the file is audible
  /// even when OS-level notification sound settings are misconfigured. [onDone] fires
  /// when playback completes or the clip is stopped.
  static Future<AudioPlayer> previewAdhan({
    String? adhanAssetKey,
    VoidCallback? onDone,
  }) async {
    final options = await AdhanSoundCatalog.discover();
    final resolved = options.any((o) => o.assetKey == adhanAssetKey)
        ? options.firstWhere((o) => o.assetKey == adhanAssetKey)
        : (options.isNotEmpty ? options.first : null);

    final player = AudioPlayer();
    Source source;
    if (resolved == null) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        source = UrlSource('android.resource://$_androidApplicationId/raw/$_androidDefaultRawName');
      } else {
        source = AssetSource('sounds/adhan.mp3');
      }
    } else {
      final assetRelative = resolved.assetKey.startsWith('assets/')
          ? resolved.assetKey.substring('assets/'.length)
          : resolved.assetKey;
      source = AssetSource(assetRelative);
    }
    player.onPlayerComplete.listen((_) {
      if (onDone != null) onDone();
    });
    await player.play(source);
    return player;
  }

  /// Pending (scheduled) prayer alerts currently queued with the OS scheduler.
  static Future<List<PendingNotificationRequest>> pendingRequests() async {
    if (!supportsPrayerNotifications) return const [];
    return _notifications.pendingNotificationRequests();
  }

  /// Notifications the user is currently seeing in the shade (Android 6+ / iOS 10+).
  static Future<List<ActiveNotification>> activeNotifications() async {
    if (!supportsPrayerNotifications) return const [];
    final all = await _notifications.getActiveNotifications();
    // Filter to channels we own so unrelated system notifications don't leak in.
    return all
        .where((n) => n.channelId == null || (n.channelId?.startsWith('prayer_alerts_') ?? false))
        .toList();
  }
}
