import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salat_pro/main.dart';
import 'package:salat_pro/providers/prayer_provider.dart';
import 'package:salat_pro/providers/settings_provider.dart';

void main() {
  testWidgets('Salat Pro loads home shell', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    final settings = SettingsProvider();
    await settings.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProxyProvider<SettingsProvider, PrayerProvider>(
            create: (_) => PrayerProvider(),
            update: (_, s, p) => p!..updateWithSettings(s),
          ),
        ],
        child: const SalatProApp(),
      ),
    );

    await tester.pump();
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('القبلة'), findsOneWidget);
  });
}
