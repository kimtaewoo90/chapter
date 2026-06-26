import 'package:chapter/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'store_screenshots/scenes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = true;
    await initializeDateFormatting('ko_KR', null);
  });

  for (final scene in StoreScreenshotScenes.all) {
    testWidgets('store screenshot ${scene.fileName}', (tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: const Locale('ko', 'KR'),
          home: scene.widget,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../store_assets/app-store/ios/6.7-inch/${scene.fileName}'),
      );
    });
  }
}
