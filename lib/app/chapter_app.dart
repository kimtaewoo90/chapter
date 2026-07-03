import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/analytics/analytics_route_observer.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import '../services/analytics_service.dart';
import '../screens/update/app_version_block_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/main_shell.dart';

class ChapterApp extends StatelessWidget {
  const ChapterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final fontId = context.watch<AppState>().fontId;
    final routeObserver = context.read<AnalyticsRouteObserver>();
    return MaterialApp(
      title: '챕터',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
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

class _LaunchPhaseTracker extends StatefulWidget {
  const _LaunchPhaseTracker({required this.child});

  final Widget child;

  @override
  State<_LaunchPhaseTracker> createState() => _LaunchPhaseTrackerState();
}

class _LaunchPhaseTrackerState extends State<_LaunchPhaseTracker> {
  LaunchPhase? _lastPhase;

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<AppState>().launchPhase;
    if (_lastPhase != phase) {
      _lastPhase = phase;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final analytics = context.read<AnalyticsService>();
        analytics.logLaunchPhase(phase.name);
        switch (phase) {
          case LaunchPhase.splash:
            analytics.logScreenView(screenName: 'splash');
          case LaunchPhase.onboarding:
            analytics.logScreenView(screenName: 'onboarding');
          case LaunchPhase.home:
            analytics.logScreenView(screenName: 'home');
          case LaunchPhase.forceUpdate:
            analytics.logScreenView(screenName: 'force_update');
          case LaunchPhase.maintenance:
            analytics.logScreenView(screenName: 'maintenance');
          case LaunchPhase.initializing:
            break;
        }
      });
    }
    return widget.child;
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

    return _LaunchPhaseTracker(
      child: switch (state.launchPhase) {
        LaunchPhase.forceUpdate || LaunchPhase.maintenance => AppVersionBlockScreen(
            gate: state.versionGate!,
            onRetry: () => state.retryVersionCheck(),
            onOpenStore: state.launchPhase == LaunchPhase.forceUpdate
                ? () => context.read<AnalyticsService>().logForceUpdateStoreTap()
                : null,
          ),
        LaunchPhase.splash => SplashScreen(onDone: () => state.finishSplash()),
        LaunchPhase.onboarding => const OnboardingScreen(),
        LaunchPhase.home => const MainShell(),
        LaunchPhase.initializing => const Scaffold(
            backgroundColor: AppTheme.paper,
            body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          ),
      },
    );
  }
}
