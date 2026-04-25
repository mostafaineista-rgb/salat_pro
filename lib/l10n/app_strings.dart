import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';

/// UI strings for Arabic (`ar`) and English (`en`). Default app language is Arabic.
class AppStrings {
  AppStrings._(this.localeCode);

  /// BCP 47 language code; only `ar` and `en` are supported.
  final String localeCode;

  bool get isArabic => localeCode == 'ar';

  bool get isEnglish => localeCode == 'en';

  static AppStrings fromLanguageCode(String code) =>
      AppStrings._(code == 'en' ? 'en' : 'ar');

  /// Hijri month names (approximate calendar UI).
  String hijriMonthName(int month1to12) {
    if (isArabic) {
      const ar = [
        '',
        'محرم',
        'صفر',
        'ربيع الأول',
        'ربيع الآخر',
        'جمادى الأولى',
        'جمادى الآخر',
        'رجب',
        'شعبان',
        'رمضان',
        'شوال',
        'ذو القعدة',
        'ذو الحجة',
      ];
      if (month1to12 < 1 || month1to12 > 12) return '';
      return ar[month1to12];
    }
    const en = [
      '',
      'Muharram',
      'Safar',
      'Rabiʻ I',
      'Rabiʻ II',
      'Jumada I',
      'Jumada II',
      'Rajab',
      'Shaʻban',
      'Ramadan',
      'Shawwal',
      'Dhuʻl-Qiʻdah',
      'Dhuʻl-Hijjah',
    ];
    if (month1to12 < 1 || month1to12 > 12) return '';
    return en[month1to12];
  }

  String formatCalendarDay(DateTime d) =>
      DateFormat.yMMMMEEEEd(localeCode).format(d);

  /// [use24HourClock] false = 12-hour with AM/PM; true = 24-hour (locale-aware).
  String formatTimeHm(DateTime d, {required bool use24HourClock}) {
    if (use24HourClock) {
      return DateFormat.Hm(localeCode).format(d);
    }
    return DateFormat.jm(localeCode).format(d);
  }

  String formatWeekday(DateTime d) => DateFormat.EEEE(localeCode).format(d);

  String formatGregorianFull(DateTime d) =>
      DateFormat.yMMMMd(localeCode).format(d);

  /// When UI is Arabic, replaces Western digits with Eastern Arabic numerals (٠–٩).
  String localizeNumerals(String input) {
    if (!isArabic) return input;
    return input.replaceAllMapped(RegExp(r'[0-9]'), (m) {
      const eastern = '٠١٢٣٤٥٦٧٨٩';
      return eastern[int.parse(m[0]!)];
    });
  }

  String prayerName(Prayer p) {
    if (isArabic) {
      return switch (p) {
        Prayer.fajr => 'الفجر',
        Prayer.sunrise => 'الشروق',
        Prayer.dhuhr => 'الظهر',
        Prayer.asr => 'العصر',
        Prayer.maghrib => 'المغرب',
        Prayer.isha => 'العشاء',
        Prayer.none => '',
      };
    }
    return switch (p) {
      Prayer.fajr => 'Fajr',
      Prayer.sunrise => 'Sunrise',
      Prayer.dhuhr => 'Dhuhr',
      Prayer.asr => 'Asr',
      Prayer.maghrib => 'Maghrib',
      Prayer.isha => 'Isha',
      Prayer.none => '',
    };
  }

  /// Uppercase label for hero (previous design used uppercase English names).
  String prayerNameHero(Prayer p) => prayerName(p).toUpperCase();

  String get home => isArabic ? 'الرئيسية' : 'Home';

  /// Home app bar: opens the notification history screen (upcoming + active alerts).
  String get homeAdhanAndAlerts => isArabic ? 'سجل التنبيهات' : 'Notification history';

  String get homeRefreshTooltip => isArabic ? 'تحديث أوقات الصلاة' : 'Refresh prayer times';

  String get walkWeatherHomeSection =>
      isArabic ? 'للمشي إلى المسجد' : 'FOR YOUR WALK';

  String get walkWeatherTitle => isArabic ? 'في الطريق' : 'Your walk';

  String get walkWeatherSubtitle => isArabic
      ? 'للمشي إلى المسجد — ليس تطبيق طقس كاملاً'
      : 'For walking to the mosque — not a full weather app';

  String walkWeatherTempLine(String air, String feel) => isArabic
      ? '$air° خارجاً · يشعر وكأنها $feel°'
      : '$air° outside · feels like $feel°';

  String get walkWeatherLoading =>
      isArabic ? 'جلب نسمة الطقس…' : 'Gathering a breath of weather…';

  String get walkWeatherCouldNotLoad => isArabic
      ? 'تعذر جلب الطقس للتو. تحقق من الاتصال وحاول مرة أخرى.'
      : 'Could not load weather just now. Check your connection and try again.';

  String get walkWeatherRetry => isArabic ? 'إعادة المحاولة' : 'Try again';

  String get walkWeatherFeelsLikeShort => isArabic ? 'الإحساس' : 'Feels';

  String get walkWeatherWindLabel => isArabic ? 'الرياح' : 'Wind';

  String get walkWeatherUvLabel => isArabic ? 'الأشعة فوق البنفسجية' : 'UV index';

  String get walkWeatherDataAttribution => isArabic
      ? 'البيانات من Open-Meteo (مجاني، دون مفتاح). اسحب للتحديث.'
      : 'Data from Open-Meteo (free, no API key). Pull down to refresh.';

  String get notificationHistoryTitle =>
      isArabic ? 'سجل التنبيهات' : 'Notification history';

  String get notificationHistorySubtitle => isArabic
      ? 'التنبيهات المجدولة والتي تظهر حالياً على جهازك. لإعدادات الأذان افتح صفحة الإعدادات.'
      : 'Scheduled and currently-showing prayer alerts on this device. Adhan configuration lives in Settings.';

  String get notificationHistoryScheduledSection =>
      isArabic ? 'المجدولة القادمة' : 'Scheduled (upcoming)';

  String get notificationHistoryActiveSection =>
      isArabic ? 'الظاهرة الآن' : 'Currently showing';

  String get notificationHistoryEmptyScheduled => isArabic
      ? 'لا توجد تنبيهات مجدولة. ستظهر هنا بعد حساب أوقات الصلاة.'
      : 'No scheduled alerts yet. They appear here after prayer times are calculated.';

  String get notificationHistoryEmptyActive =>
      isArabic ? 'لا توجد تنبيهات ظاهرة الآن.' : 'No alerts currently in the shade.';

  String get notificationHistoryRefresh =>
      isArabic ? 'تحديث' : 'Refresh';

  String get adhanPreviewTooltip =>
      isArabic ? 'تجربة الأذان داخل التطبيق' : 'Preview in-app';

  String get adhanPreviewStopTooltip =>
      isArabic ? 'إيقاف التجربة' : 'Stop preview';

  /// Identifier shown next to each pending notification for debugging.
  String notificationIdLabel(int id) =>
      isArabic ? 'الرقم $id' : 'ID $id';

  String get notifyOutcomeDeliveredTitle =>
      isArabic ? 'تم الإرسال' : 'Notification delivered';

  String get notifyOutcomeDeliveredBody =>
      isArabic ? 'يفترض أن تسمع الأذان وترى التنبيه الآن.' : 'You should see the banner and hear the adhan now.';

  String get notifyOutcomeScheduledTitle =>
      isArabic ? 'تم جدولة الاختبار' : 'Test scheduled';

  String notifyOutcomeScheduledBody(int seconds) => isArabic
      ? 'سيظهر التنبيه خلال $seconds ثانية. أبق التطبيق مفتوحاً إن استطعت.'
      : 'The alert will appear in $seconds seconds. Keep the app open if you can.';

  String get notifyOutcomePermissionTitle =>
      isArabic ? 'إذن التنبيهات مرفوض' : 'Notification permission denied';

  String get notifyOutcomePermissionBody => isArabic
      ? 'السماح بالتنبيهات مطلوب لتشغيل الأذان. اضغط "فتح الإعدادات" وفعّل التنبيهات لتطبيق "الصلاة برو".'
      : 'Notifications are required to play the adhan. Tap "Open settings" and turn notifications on for Salat Pro.';

  String get notifyOutcomePermissionPermanentBody => isArabic
      ? 'تم رفض إذن التنبيهات نهائياً. افتح الإعدادات يدوياً وفعّل التنبيهات لتطبيق "الصلاة برو".'
      : 'Notification permission was permanently denied. Open system settings and turn notifications on for Salat Pro.';

  String get notifyOutcomeAppDisabledTitle =>
      isArabic ? 'التنبيهات متوقفة' : 'Notifications are off';

  String get notifyOutcomeAppDisabledBody => isArabic
      ? 'التنبيهات متوقفة لتطبيق "الصلاة برو" على مستوى النظام. فعّلها من إعدادات التطبيق.'
      : 'Notifications are disabled for Salat Pro at the system level. Turn them on in app settings.';

  String get notifyOutcomeChannelBlockedTitle =>
      isArabic ? 'القناة محجوبة' : 'Channel silenced';

  String get notifyOutcomeChannelBlockedBody => isArabic
      ? 'تم إرسال التنبيه لكنه لم يظهر — غالباً لأن قناة "تنبيهات الصلاة" مضبوطة على صامت. افتح الإعدادات وأعد تفعيل الصوت للقناة.'
      : 'The notification was posted but not shown — the "Prayer alerts" channel is likely silenced. Open settings and re-enable sound for the channel.';

  String get notifyOutcomeDeliveryFailedTitle =>
      isArabic ? 'فشل الإرسال' : 'Delivery failed';

  String get notifyOutcomeDeliveryFailedBody => isArabic
      ? 'حدث خطأ أثناء إرسال التنبيه. غالباً كان ملف صوت الأذان مفقوداً من نسخة الإصدار — تم إصلاح ذلك. إن استمر الخطأ، انظر التفاصيل أدناه.'
      : 'Posting the notification failed. In release builds this was often caused by Android removing notification sound files during shrinking — that is now prevented. If it still fails, see the technical details below.';

  String get openAppSettingsLabel =>
      isArabic ? 'فتح الإعدادات' : 'Open settings';

  String get okLabel => isArabic ? 'حسناً' : 'OK';
  String get qibla => isArabic ? 'القبلة' : 'Qibla';
  String get mosque => isArabic ? 'مسجد' : 'Mosque';
  String get calendar => isArabic ? 'التقويم' : 'Calendar';
  String get azkar => isArabic ? 'الأذكار' : 'Azkar';
  String get settings => isArabic ? 'الإعدادات' : 'Settings';

  String get prayerTimesSection =>
      isArabic ? 'أوقات الصلاة' : 'PRAYER TIMES';

  String get spiritualReflection =>
      isArabic ? 'ما تيسر من الذكر اليومي' : 'SPIRITUAL DAILY REFLECTION';

  String get dailyHadith =>
      isArabic ? 'حديث اليوم' : 'DAILY HADITH';

  String get hadithSourceLine => isArabic
      ? 'المصدر: fawazahmed0/hadith-api (عربي + إنجليزي عبر jsDelivr)'
      : 'Source: fawazahmed0/hadith-api (Arabic + English via jsDelivr CDN)';

  /// Shown under the title when the live API is not available yet.
  String get hadithBundledHint => isArabic
      ? 'نص مضمّن في التطبيق إلى أن يتاح التحميل من الشبكة (اسحب للتحديث).'
      : 'Built-in excerpt until the CDN loads (pull to refresh).';

  /// Footer when showing the bundled excerpt instead of a live API response.
  String get hadithBundledFooter =>
      isArabic ? 'متن مدمج • صحيح البخاري (عربي/إنجليزي)' : 'Bundled excerpt • Sahih al-Bukhari (EN/AR)';

  String get calculatingTimes =>
      isArabic ? 'جاري حساب الأوقات…' : 'Calculating sanctuary times...';

  String get timeToPrayer =>
      isArabic ? 'الوقت المتبقي للصلاة: ' : 'TIME TO PRAYER: ';

  String get detectingCity => isArabic ? 'جاري التحديد…' : 'Detecting...';

  // Settings
  String get settingsTitle => isArabic ? 'الإعدادات' : 'SETTINGS';

  String get sectionLocation => isArabic ? 'الموقع' : 'LOCATION';

  String get sectionAdhan =>
      isArabic ? 'إشعارات الأذان' : 'ADHAN NOTIFICATIONS';

  String get adhanSoundTitle => isArabic ? 'صوت الأذان' : 'Adhan sound';

  String get adhanSoundSubtitle => isArabic
      ? 'يُعرض الاسم من اسم الملف في مجلد الأصول.'
      : 'The label is taken from each file name under assets.';

  String get adhanSoundEmpty => isArabic
      ? 'لا توجد ملفات أذان في التطبيق بعد.'
      : 'No adhan sound files in the app yet.';

  String get adhanSoundEmptyHint => isArabic
      ? 'أضف ملفات صوت (مثل ‎.mp3‎) داخل ‎assets/sounds/‎ في المشروع، ثم نفّذ ‎Stop‎ ثم ‎Run‎ من جديد حتى تُسجَّل الملفات.'
      : 'Add audio files (e.g. .mp3) to assets/sounds/ in the project, then do a full restart '
          '(`flutter run` or Stop and Run) so they are bundled.';

  String get adhanSoundLoadError => isArabic
      ? 'تعذّر تحميل قائمة الأصوات.'
      : 'Could not load the list of adhan files.';

  String get adhanSoundWebNote => isArabic
      ? 'تنبيهات أوقات الصلاة (الأذان) تعمل في تطبيق أندرويد/آي أو إس فقط؛ هنا تختار الصوت المخزّن لحسابك.'
      : 'Prayer-time adhan alerts run in the Android/iOS app only; here you pick the sound that is saved.';

  String get sectionPrayerCalc =>
      isArabic ? 'حساب أوقات الصلاة' : 'PRAYER CALCULATION';

  String get sectionAppPrefs =>
      isArabic ? 'تفضيلات التطبيق' : 'APP PREFERENCES';

  String get sectionPermissions => isArabic ? 'الأذونات' : 'PERMISSIONS';

  String get languageLabel => isArabic ? 'اللغة' : 'Language';

  String get languageArabic => isArabic ? 'العربية' : 'Arabic';

  String get languageEnglish => isArabic ? 'الإنجليزية' : 'English';

  String get appearance => isArabic ? 'المظهر' : 'Appearance';

  String get appearanceSubtitle => isArabic
      ? 'كمّل النظام أو اختر الفاتح أو الداكن.'
      : 'Match the system or choose light or dark.';

  String get themeAuto => isArabic ? 'تلقائي' : 'Auto';
  String get themeLight => isArabic ? 'فاتح' : 'Light';
  String get themeDark => isArabic ? 'داكن' : 'Dark';

  String get clockFormatLabel => isArabic ? 'تنسيق الوقت' : 'Time format';

  String get clockFormatSubtitle => isArabic
      ? '١٢ ساعة (ص/م) أو ٢٤ ساعة.'
      : '12-hour (AM/PM) or 24-hour.';

  String get clockFormat12 => isArabic ? '١٢ ساعة' : '12-hour';

  String get clockFormat24 => isArabic ? '٢٤ ساعة' : '24-hour';

  String get manualLocation => isArabic ? 'الموقع اليدوي' : 'Manual Location';

  String get manualLocationSubtitle =>
      isArabic ? 'تعيين المدينة يدوياً' : 'Set your city manually';

  String get currentCity => isArabic ? 'المدينة الحالية' : 'Current City';

  String get manualCity => isArabic ? 'المدينة (يدوي)' : 'Manual City';

  String get detect => isArabic ? 'اكتشاف' : 'DETECT';

  String get searchCityHint => isArabic
      ? 'ابحث عن مدينة أو عنوان (OpenStreetMap)'
      : 'Search city or address (OpenStreetMap)';

  String get osmHint => isArabic
      ? 'اقتراحات من OpenStreetMap Nominatim (مجاني). أو اضغط البحث لاستخدام ترميز الجهاز.'
      : 'Suggestions from OpenStreetMap Nominatim (free). Or press search to use device geocoding.';

  String locationSetTo(String label) =>
      isArabic ? 'تم ضبط الموقع إلى $label' : 'Location set to $label';

  String snackLocationShort(String label) =>
      isArabic ? 'الموقع: $label' : 'Location: $label';

  String get locationNotFound => isArabic
      ? 'تعذّر العثور على الموقع. حاول مرة أخرى.'
      : 'Could not find location. Please try again.';

  String get testAdhanTitle =>
      isArabic ? 'اختبار تنبيه الأذان' : 'Test adhan alert';

  String get testAdhanBody => isArabic
      ? 'على أندرويد قد يتبع الصوت مستوى منبّه الإنذار عند صمت الرنين. الاهتزاز يعتمد على النظام وعدم الإزعاج.'
      : 'Android uses alarm audio so sound may follow alarm volume when the ringer is silent. '
          'Vibration still depends on system & DND settings.';

  String get testNow => isArabic ? 'اختبار الآن' : 'Test now';

  String get testIn15s => isArabic ? 'اختبار بعد 15 ث' : 'Test in 15s';

  String get testFired => isArabic ? 'تم إرسال إشعار الاختبار' : 'Test notification fired now';

  String get testScheduled15 =>
      isArabic ? 'تم جدولة الاختبار بعد 15 ثانية' : 'Scheduled test in 15 seconds';

  String get methodMwl =>
      isArabic ? 'رابطة العالم الإسلامي' : 'Muslim World League';

  String get methodIsna => isArabic
      ? 'الجمعية الإسلامية لأمريكا الشمالية'
      : 'Islamic Society of North America';

  String get methodEgypt =>
      isArabic ? 'الهيئة المصرية العامة' : 'Egyptian General Authority';

  String get openSystemSettings =>
      isArabic ? 'فتح إعدادات النظام' : 'Open system settings';

  String get openSystemSettingsSubtitle => isArabic
      ? 'الموقع والإشعارات والمنبّهات الدقيقة'
      : 'Location, notifications, and exact alarms';

  String aboutVersionLine(String version) =>
      isArabic ? 'صلاة برو v$version' : 'Salat Pro v$version';

  String get sectionAboutBrand => isArabic ? 'حول التطبيق' : 'ABOUT';

  String get aboutPageTitle => isArabic ? 'حول التطبيق' : 'About';

  String aboutPublishedBy(String studio) =>
      isArabic ? 'يُنشر بواسطة $studio.' : 'Published by $studio.';

  String aboutStudioBlurb(String shortName, String studioDisplayName) => isArabic
      ? '$studioDisplayName ($shortName) — تطبيقات وألعاب من بلاد الرافدين بجودة وتجربة واضحة.'
      : '$studioDisplayName ($shortName) — apps and games from Mesopotamia with a focus on quality and clarity.';

  String get aboutPackagePrefixLabel =>
      isArabic ? 'بادئة حزمة المطوّر' : 'Developer package prefix';

  String get privacyPolicyMenu => isArabic ? 'سياسة الخصوصية' : 'Privacy policy';

  String get privacyPolicyTitleFull =>
      isArabic ? 'سياسة الخصوصية' : 'Privacy Policy';

  String get privacyPolicyTileSubtitle => isArabic
      ? 'اقرأ كيف نتعامل مع بياناتك'
      : 'How we handle your data';

  String get contactSupportSection =>
      isArabic ? 'التواصل والدعم' : 'CONTACT & SUPPORT';

  String get labelWebsite => isArabic ? 'الموقع' : 'Website';

  String get labelSupportEmail => isArabic ? 'بريد الدعم' : 'Support';

  String get labelPrivacyEmail => isArabic ? 'بريد الخصوصية' : 'Privacy';

  String get labelContactEmail => isArabic ? 'بريد التواصل' : 'Contact';

  String privacyPolicyPublisher(String studio) => isArabic
      ? 'يشرح هذا المستند كيف يتعامل تطبيق «صلاة برو» مع المعلومات على جهازك. الناشر: $studio.'
      : 'This policy describes how Salat Pro handles information on your device. Publisher: $studio.';

  String get privacyPolicyBodyLocation => isArabic
      ? 'الموقع: يُستخدم لحساب أوقات الصلاة والقبلة والمساجد القريبة والطقس الاختياري عندما تسمح بذلك. لا نبيع بياناتك.'
      : 'Location: Used to compute prayer times, Qibla, nearby mosques, and optional weather when you allow it. We do not sell your data.';

  String get privacyPolicyBodyNotifications => isArabic
      ? 'التنبيهات: تُجدول محلياً على جهازك لتنبيهات الصلاة عند تفعيلها.'
      : 'Notifications: Prayer alerts are scheduled locally on your device when you enable them.';

  String get privacyPolicyBodyDataSales => isArabic
      ? 'لا نبيع معلوماتك الشخصية لأطراف ثالثة.'
      : 'We do not sell your personal information to third parties.';

  String get privacyPolicyQuestionsIntro => isArabic
      ? 'لأسئلة الخصوصية، راسلنا على:'
      : 'For privacy questions, contact us at:';

  // App updates
  String get sectionAppUpdate =>
      isArabic ? 'التحديث' : 'Updates';

  String get checkForUpdates => isArabic ? 'التحقق من التحديث' : 'Check for updates';

  String get checkForUpdatesSubtitle => isArabic
      ? 'تنزيل وإعادة تثبيت نسخة جديدة عند توافرها'
      : 'Download a new build when a release is available';

  String get updateChecking => isArabic ? 'جاري التحقق…' : 'Checking…';

  String get updateOnLatest =>
      isArabic ? 'أنت تستخدم أحدث نسخة' : 'You are on the latest version';

  String get updateError =>
      isArabic ? 'تعذر التحقق من التحديث' : 'Could not check for updates';

  String updateNewVersionTitle(String v) => isArabic
      ? 'متوفر إصدار v$v'
      : 'Version v$v is available';

  String get updateDownloadInstall => isArabic ? 'تنزيل وتحديث' : 'Download and update';

  String get updateOpenInBrowser => isArabic ? 'فتح' : 'Open';

  String get updateLater => isArabic ? 'لاحقاً' : 'Later';

  String get updateDownloading => isArabic ? 'جاري التنزيل…' : 'Downloading…';

  String updateSessionSnack(String v) => isArabic
      ? 'متوفر تحديث (v$v) — اذهب إلى الإعدادات'
      : 'An update (v$v) is available — go to Settings';

  String get updateSettingsSnackbarAction =>
      isArabic ? 'الإعدادات' : 'Settings';

  String get updateManifestUnconfigured => isArabic
      ? 'رابط ملف التحديث غير مضبوط في التطبيق'
      : 'Update URL is not configured in the app';

  // Qibla
  String get qiblaHeading => isArabic ? 'القبلة' : 'QIBLA';

  /// Decorative Arabic line under the Latin heading (always Arabic script).
  String get qiblaArabicCaption => 'اتجاه القبلة';

  String get azimuthFromNorth =>
      isArabic ? 'السمت من الشمال' : 'Azimuth from north';

  String get compassUnavailableWeb => isArabic
      ? 'البوصلة غير متوفرة — أدر حتى يشير المؤشر نحو الشمال.'
      : 'Compass unavailable — rotate until the needle meets north on your device.';

  String get measuringDistance => isArabic
      ? 'قياس المسافة إلى الحرم المكي…'
      : 'Measuring distance to Masjid al-Haram…';

  String get distanceUnavailable => isArabic
      ? 'المسافة غير متوفرة — فعّل الموقع للتقدير.'
      : 'Distance unavailable — enable location for an estimate.';

  String get distanceToKaaba =>
      isArabic ? 'المسافة إلى الكعبة' : 'Distance to Kaaba';

  String get greatCircleHint => isArabic
      ? 'مسار كبير عبر إحداثيات GPS'
      : 'Great-circle via your GPS fix';

  String facingQibla(double delta) => isArabic
      ? 'مواجه للقبلة • ${delta.toStringAsFixed(1)}°'
      : 'Facing Qibla • ${delta.toStringAsFixed(1)}°';

  String turnRight(double deg) =>
      isArabic ? 'انعطف يميناً ${deg.toStringAsFixed(1)}°' : 'Turn right ${deg.toStringAsFixed(1)}°';

  String turnLeft(double deg) =>
      isArabic ? 'انعطف يساراً ${deg.toStringAsFixed(1)}°' : 'Turn left ${deg.toStringAsFixed(1)}°';

  String get locationAccessRequired => isArabic
      ? 'مطلوب الوصول إلى الموقع'
      : 'Location Access Required';

  String errorLine(Object error) =>
      isArabic ? 'خطأ: $error' : 'Error: $error';

  // Calendar
  String get upcomingEvents =>
      isArabic ? 'المناسبات القادمة' : 'UPCOMING EVENTS';

  String get gregorianLabel => isArabic ? 'ميلادي' : 'GREGORIAN';

  String get dayLabel => isArabic ? 'اليوم' : 'DAY';

  String get ramadan2026 =>
      isArabic ? 'رمضان 2026' : 'Ramadan 2026';

  String get eidFitr => isArabic ? 'عيد الفطر' : 'Eid Al-Fitr';

  String get hajjSeason => isArabic ? 'موسم الحج' : 'Hajj Season';

  String get eidAdha => isArabic ? 'عيد الأضحى' : 'Eid Al-Adha';

  String get ahSuffix => isArabic ? 'هـ' : 'AH';

  // Nearest mosque
  String get nearestMosqueTitle =>
      isArabic ? 'أقرب مسجد' : 'NEAREST MOSQUE';

  String get refreshMapsTooltip => isArabic
      ? 'تحديث الموقع والمساجد'
      : 'Refresh location & mosques';

  String get loadingMosques =>
      isArabic ? 'جاري تحميل المساجد…' : 'Loading mosques…';

  String withinKm(int km) =>
      isArabic ? 'ضمن $km كم' : 'Within $km km';

  String get retry => isArabic ? 'إعادة' : 'Retry';

  String get findingLocation =>
      isArabic ? 'جاري العثور على موقعك…' : 'Finding your location…';

  String get yourLocationTooltip =>
      isArabic ? 'موقعك' : 'Your location';

  String get locationOffTitle => isArabic ? 'الموقع مغلق' : 'Location off';

  String get locationOffBody => isArabic
      ? 'يحتاج صلاة برو إلى موقعك للعثور على المساجد القريبة. اضغط إعادة والسماح عند الطلب.'
      : 'Salat Pro needs your location to find nearby mosques. Tap retry and allow access when prompted.';

  String get locationBlockedTitle =>
      isArabic ? 'الموقع محظور' : 'Location blocked';

  String get locationBlockedBody => isArabic
      ? 'تم رفض إذن الموقع بشكل دائم. افتح إعدادات النظام لتمكينه لتطبيق صلاة برو.'
      : 'Location permission was denied permanently. Open system settings to enable it for Salat Pro.';

  String get locationServiceOffTitle =>
      isArabic ? 'خدمة الموقع مغلقة' : 'Location services off';

  String get locationServiceOffBody => isArabic
      ? 'شغّل موقع الجهاز (GPS) ثم اضغط تحديثاً.'
      : 'Turn on device location (GPS), then tap refresh.';

  String get locationUnavailableTitle =>
      isArabic ? 'الموقع غير متاح' : 'Location unavailable';

  String get locationUnavailableBody => isArabic
      ? 'تعذّر قراءة موقعك. حاول في الخارج أو تحقق من الاتصال.'
      : 'Could not read your position. Try again outdoors or check your connection.';

  String get openSettings => isArabic ? 'فتح الإعدادات' : 'Open settings';

  String get locationSettings =>
      isArabic ? 'إعدادات الموقع' : 'Location settings';

  String get noMosquesFound => isArabic
      ? 'لا توجد أماكن عبادة مسجلة في خريطة الشارع المفتوح ضمن هذا النطاق.\n'
          'جرّب التحديث بعد الانتقال، أو وسّع التغطية بتحرير OSM في منطقتك.'
      : 'No Muslim places of worship found in OpenStreetMap within this radius.\n'
          'Try refreshing after moving, or widen coverage by editing OSM in your area.';

  String get openInMapsTooltip =>
      isArabic ? 'فتح في الخرائط' : 'Open in maps';

  String get couldNotOpenMaps =>
      isArabic ? 'تعذّر فتح تطبيق الخرائط' : 'Could not open maps app';

  String formatDistanceMeters(double meters) {
    if (meters < 1000) {
      return isArabic ? '${meters.round()} م' : '${meters.round()} m';
    }
    return isArabic
        ? '${(meters / 1000).toStringAsFixed(1)} كم'
        : '${(meters / 1000).toStringAsFixed(1)} km';
  }

  // Azkar screen
  String get tasbihAzkarTitle =>
      isArabic ? 'التسبيح والأذكار' : 'TASBIH & AZKAR';

  String get targetLabel =>
      isArabic ? 'الهدف' : 'TARGET';

  String get dailyRemembrancesSection =>
      isArabic ? 'أذكار يومية' : 'DAILY REMEMBRANCES';

  String get tasbihPresetsSection =>
      isArabic ? 'مسبحة سريعة' : 'TASBIH PRESETS';

  // Notifications
  String timeForPrayer(String prayerLabel) =>
      isArabic ? 'حان وقت صلاة $prayerLabel' : 'Time for $prayerLabel';

  String get notificationBody =>
      isArabic ? 'السلام على المصلّين.' : 'Peace be upon those who pray.';

  String get channelPrayerAlerts =>
      isArabic ? 'تنبيهات الصلاة' : 'Prayer alerts';

  String get channelPrayerAlertsDesc => isArabic
      ? 'الأذان في أوقات الصلاة. على أندرويد يستخدم صوت المنبّه.'
      : 'Adhan at prayer times. Uses alarm audio on Android so alerts can follow alarm volume when the ringer is silenced (subject to DND and device settings).';

  String get channelPrayerAlertsDescShort => isArabic
      ? 'الأذان في أوقات الصلاة. مستوى المنبّه على أندرويد.'
      : 'Adhan at prayer times. Uses alarm volume on Android (check alarm volume if the phone ringer is silent).';

  String get adhanTestTitle => isArabic ? 'اختبار الأذان' : 'Adhan test';

  String get adhanTestBody => isArabic
      ? 'إن سمح مستوى الصوت، ستسمع الأذان وتحس بالاهتزاز.'
      : 'If volume allows, you should hear adhan and feel vibration.';

  String get adhanTestScheduledTitle =>
      isArabic ? 'اختبار الأذان (مجدول)' : 'Adhan test (scheduled)';

  String get adhanTestScheduledBody =>
      isArabic ? 'اختبار أذان مجدول.' : 'Scheduled adhan test.';

  String get couldNotRetrieveLocation =>
      isArabic ? 'تعذّر الحصول على الموقع' : 'Could not retrieve location';

  String get locationGeneric => isArabic ? 'الموقع' : 'Location';

  String get moonPhaseTitle =>
      isArabic ? 'منازل القمر' : 'Moon Phase';

  String get illumination =>
      isArabic ? 'الإضاءة' : 'Illumination';

  String get moonAgeLabel => isArabic ? 'العمر' : 'Age';

  String get days => isArabic ? 'أيام' : 'days';

  String get hijriMonthLabel =>
      isArabic ? 'الشهر الهجري' : 'Hijri Month';

  String get moonPhaseFootnote => isArabic
      ? 'تنبيه: الحسابات الفلكية قد تختلف عن الرؤية الشرعية الرسمية للقمر'
      : 'Note: Astronomical calculations may differ from official moon sightings';
}
