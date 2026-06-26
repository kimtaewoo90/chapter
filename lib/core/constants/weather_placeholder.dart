/// MVP 초기에 넣었던 가짜 날씨 — API 연동 전까지 UI·저장에 사용하지 않음
const kPlaceholderWeather = '맑음';
const kPlaceholderTemperature = '23°C';

bool isPlaceholderWeather(String? weather, String? temperature) {
  if (weather == null || weather.isEmpty) return true;
  return weather == kPlaceholderWeather &&
      (temperature == null || temperature.isEmpty || temperature == kPlaceholderTemperature);
}
