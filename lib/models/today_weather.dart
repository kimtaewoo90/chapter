class TodayWeather {
  const TodayWeather({
    required this.weather,
    required this.temperature,
    required this.fetchedAt,
  });

  final String weather;
  final String temperature;
  final DateTime fetchedAt;

  bool isFresh(Duration ttl) => DateTime.now().difference(fetchedAt) < ttl;
}
