import 'package:weather/weather.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  late WeatherFactory _wf;
  static const String _apiKey = 'eb0b34798993f58a1f10fc35bf3a464d'; // Replace with your actual API key

  WeatherService() {
    _wf = WeatherFactory(_apiKey);
  }

  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current weather for user's location
  Future<Weather> getCurrentWeather() async {
    // Check and request permissions
    bool hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Get user's current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );

    // Fetch weather by coordinates
    Weather weather = await _wf.currentWeatherByLocation(
      position.latitude,
      position.longitude,
    );

    return weather;
  }

  /// Get 5-day forecast for user's location
  Future<List<Weather>> getForecast() async {
    // Check and request permissions
    bool hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Get user's current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );

    // Fetch 5-day forecast
    List<Weather> forecast = await _wf.fiveDayForecastByLocation(
      position.latitude,
      position.longitude,
    );

    return forecast;
  }

  /// Get weather icon URL
  String getWeatherIconUrl(String? iconCode) {
    if (iconCode == null) return '';
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  /// Format temperature
  String formatTemperature(double? temp) {
    if (temp == null) return '--°C';
    return '${temp.round()}°C';
  }
}
