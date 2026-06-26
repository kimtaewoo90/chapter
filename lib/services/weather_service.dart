import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/weather_config.dart';
import '../models/today_weather.dart';

/// OpenWeatherMap 현재 날씨 — 캐시·위치 1회로 API/배터리 부담 최소화
class WeatherService {
  TodayWeather? _memoryCache;

  Future<TodayWeather?> fetchCurrentIfNeeded({bool force = false}) async {
    if (!WeatherConfig.isConfigured) return null;

    if (!force &&
        _memoryCache != null &&
        _memoryCache!.isFresh(WeatherConfig.cacheTtl)) {
      return _memoryCache;
    }

    final disk = await _loadDiskCache();
    if (!force && disk != null && disk.isFresh(WeatherConfig.cacheTtl)) {
      _memoryCache = disk;
      return disk;
    }

    final position = await _currentPosition();
    if (position == null) return _memoryCache ?? disk;

    try {
      final uri = Uri.https(
        'api.openweathermap.org',
        '/data/2.5/weather',
        {
          'lat': '${position.latitude}',
          'lon': '${position.longitude}',
          'appid': WeatherConfig.openWeatherApiKey,
          'units': 'metric',
          'lang': 'kr',
        },
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('WeatherService: API ${response.statusCode}');
        return _memoryCache ?? disk;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final main = data['main'] as Map<String, dynamic>?;
      final weatherList = data['weather'] as List<dynamic>?;
      if (main == null || weatherList == null || weatherList.isEmpty) {
        return _memoryCache ?? disk;
      }

      final desc = (weatherList.first as Map<String, dynamic>)['description'] as String?;
      final temp = main['temp'] as num?;
      if (desc == null || temp == null) return _memoryCache ?? disk;

      final result = TodayWeather(
        weather: _capitalizeKr(desc),
        temperature: '${temp.round()}°C',
        fetchedAt: DateTime.now(),
      );

      _memoryCache = result;
      await _saveDiskCache(result, position.latitude, position.longitude);
      return result;
    } catch (e, st) {
      debugPrint('WeatherService: fetch failed — $e\n$st');
      return _memoryCache ?? disk;
    }
  }

  Future<Position?> _currentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: WeatherConfig.locationTimeout,
        ),
      );
    } catch (e) {
      debugPrint('WeatherService: location — $e');
      return null;
    }
  }

  String _capitalizeKr(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1);
  }

  static const _diskKey = 'owm_weather_cache_v1';

  Future<TodayWeather?> _loadDiskCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_diskKey);
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return TodayWeather(
        weather: m['weather'] as String,
        temperature: m['temperature'] as String,
        fetchedAt: DateTime.parse(m['fetchedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveDiskCache(TodayWeather w, double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _diskKey,
      jsonEncode({
        'weather': w.weather,
        'temperature': w.temperature,
        'fetchedAt': w.fetchedAt.toIso8601String(),
        'lat': lat,
        'lon': lon,
      }),
    );
  }
}
