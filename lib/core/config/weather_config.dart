import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherConfig {
  WeatherConfig._();

  static String get openWeatherApiKey {
    const fromDefine = String.fromEnvironment('OPENWEATHER_API_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['OPENWEATHER_API_KEY']?.trim() ?? '';
  }

  static bool get isConfigured => openWeatherApiKey.isNotEmpty;

  /// 같은 위치·날씨 재요청 최소 간격
  static const Duration cacheTtl = Duration(minutes: 45);

  static const Duration locationTimeout = Duration(seconds: 8);
}
