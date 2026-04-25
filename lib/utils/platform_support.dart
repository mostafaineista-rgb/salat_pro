import 'package:flutter/foundation.dart';

/// Live compass Qibla stream (mobile sensors only).
bool get supportsQiblahCompass =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Local prayer notifications (mobile OS integration).
bool get supportsPrayerNotifications =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Choosing the Adhan clip from [assets/sounds] in Settings. Available on web and
/// mobile; actual scheduled alerts still require [supportsPrayerNotifications].
bool get supportsAdhanSettingsUi =>
    kIsWeb ||
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
