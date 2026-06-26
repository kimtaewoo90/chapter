import 'package:flutter/material.dart';

import '../../services/analytics_service.dart';

class AnalyticsRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  AnalyticsRouteObserver(this._analytics);

  final AnalyticsService _analytics;

  void _track(Route<dynamic> route) {
    if (route is! PageRoute) return;
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;
    _analytics.logScreenView(screenName: name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _track(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _track(previousRoute);
  }
}
