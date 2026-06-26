import 'package:flutter/material.dart';

import '../core/config/weather_config.dart';
import '../core/theme/app_theme.dart';
import '../models/today_weather.dart';

/// 실측 날씨만 표시 (API·위치 없으면 숨김)
class TodayWeatherLine extends StatelessWidget {
  const TodayWeatherLine({
    super.key,
    required this.weather,
    required this.loading,
  });

  final TodayWeather? weather;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (!WeatherConfig.isConfigured) return const SizedBox.shrink();
    if (!loading && weather == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        children: [
          Icon(
            Icons.cloud_outlined,
            size: 18,
            color: AppTheme.inkMuted.withValues(alpha: loading ? 0.4 : 0.85),
          ),
          const SizedBox(width: 8),
          if (loading && weather == null)
            Text(
              '날씨 불러오는 중…',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
            )
          else if (weather != null)
            Text(
              '${weather!.weather} · ${weather!.temperature}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
            ),
        ],
      ),
    );
  }
}
