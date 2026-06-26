import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/main_shell.dart';

class ChapterApp extends StatelessWidget {
  const ChapterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final fontId = context.watch<AppState>().fontId;
    return MaterialApp(
      title: '챕터',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(fontId),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _AppRouter(),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (!state.initialized || state.launchPhase == LaunchPhase.initializing) {
      return const Scaffold(
        backgroundColor: AppTheme.paper,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    switch (state.launchPhase) {
      case LaunchPhase.splash:
        return SplashScreen(onDone: () => state.finishSplash());
      case LaunchPhase.onboarding:
        return const OnboardingScreen();
      case LaunchPhase.home:
        return const MainShell();
      case LaunchPhase.initializing:
        return const Scaffold(
          backgroundColor: AppTheme.paper,
          body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
        );
    }
  }
}
