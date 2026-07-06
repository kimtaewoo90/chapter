import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/chapter_app.dart';
import 'core/analytics/analytics_route_observer.dart';
import 'core/config/ai_config.dart';
import 'core/firebase_bootstrap.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'services/analytics_service.dart';
import 'services/app_version_service.dart';
import 'services/chapter_service.dart';
import 'services/entry_service.dart';
import 'services/local_chapter_service.dart';
import 'services/local_entry_service.dart';
import 'services/local_story_arc_service.dart';
import 'services/monthly_review_service.dart';
import 'services/photo_storage_service.dart';
import 'services/story_arc_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  if (kDebugMode) {
    final issue = AiConfig.geminiConfigIssue;
    if (issue != null) {
      debugPrint('⚠️ Gemini: $issue');
    } else {
      debugPrint('✓ Gemini API key loaded (${AiConfig.geminiModel})');
    }
  }
  await initializeDateFormatting('ko_KR', null);
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await configureFirebaseAuth();
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }
  final analytics = AnalyticsService();
  await analytics.initialize();
  final analyticsObserver = AnalyticsRouteObserver(analytics);
  runApp(ChapterRoot(analytics: analytics, analyticsObserver: analyticsObserver));
}

class ChapterRoot extends StatelessWidget {
  const ChapterRoot({
    super.key,
    required this.analytics,
    required this.analyticsObserver,
  });

  final AnalyticsService analytics;
  final AnalyticsRouteObserver analyticsObserver;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: analytics),
        Provider.value(value: analyticsObserver),
        Provider(create: (_) => LocalEntryService()),
        Provider(create: (_) => LocalChapterService()),
        Provider(create: (_) => StoryArcService()),
        Provider(create: (_) => MonthlyReviewService()),
        Provider(
          create: (ctx) => LocalStoryArcService(
            cloud: ctx.read<StoryArcService>(),
            monthlyReviews: ctx.read<MonthlyReviewService>(),
          ),
        ),
        Provider(create: (_) => PhotoStorageService()),
        Provider(create: (_) => EntryService()),
        Provider(create: (_) => ChapterService()),
        Provider(create: (_) => AppVersionService()),
        ChangeNotifierProvider(
          create: (ctx) => AppState(
            entries: ctx.read<LocalEntryService>(),
            chapters: ctx.read<LocalChapterService>(),
            storyArcs: ctx.read<LocalStoryArcService>(),
            photos: ctx.read<PhotoStorageService>(),
            cloudEntries: ctx.read<EntryService>(),
            cloudChapters: ctx.read<ChapterService>(),
            appVersion: ctx.read<AppVersionService>(),
          )..initialize(),
        ),
      ],
      child: const ChapterApp(),
    );
  }
}
