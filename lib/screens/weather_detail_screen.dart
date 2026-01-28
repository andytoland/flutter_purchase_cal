import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart';

class WeatherDetailScreen extends StatefulWidget {
  const WeatherDetailScreen({super.key});

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  final WeatherService _weatherService = WeatherService();
  Weather? _currentWeather;
  List<Weather>? _forecast;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final current = await _weatherService.getCurrentWeather();
      final forecast = await _weatherService.getForecast();

      setState(() {
        _currentWeather = current;
        _forecast = forecast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeatherData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadWeatherData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWeatherData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_currentWeather != null) ...[
                        _buildCurrentWeatherCard(),
                        const SizedBox(height: 24),
                        _buildWeatherDetails(),
                        const SizedBox(height: 24),
                      ],
                      if (_forecast != null && _forecast!.isNotEmpty) ...[
                        const Text(
                          'Forecast',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildForecastList(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    final weather = _currentWeather!;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              weather.areaName ?? 'Unknown',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, MMMM d').format(weather.date ?? DateTime.now()),
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (weather.weatherIcon != null)
                  Image.network(
                    _weatherService.getWeatherIconUrl(weather.weatherIcon),
                    width: 80,
                    height: 80,
                  ),
                const SizedBox(width: 16),
                Text(
                  _weatherService.formatTemperature(weather.temperature?.celsius),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              weather.weatherDescription ?? '',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Feels like ${_weatherService.formatTemperature(weather.tempFeelsLike?.celsius)}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetails() {
    final weather = _currentWeather!;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.water_drop,
              'Humidity',
              '${weather.humidity?.round() ?? '--'}%',
            ),
            _buildDetailRow(
              Icons.air,
              'Wind Speed',
              '${weather.windSpeed?.round() ?? '--'} m/s',
            ),
            _buildDetailRow(
              Icons.compress,
              'Pressure',
              '${weather.pressure?.round() ?? '--'} hPa',
            ),
            if (weather.cloudiness != null)
              _buildDetailRow(
                Icons.cloud,
                'Cloudiness',
                '${weather.cloudiness}%',
              ),
            if (weather.sunrise != null)
              _buildDetailRow(
                Icons.wb_sunny,
                'Sunrise',
                DateFormat('HH:mm').format(weather.sunrise!),
              ),
            if (weather.sunset != null)
              _buildDetailRow(
                Icons.wb_twilight,
                'Sunset',
                DateFormat('HH:mm').format(weather.sunset!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastList() {
    // Group forecast by day
    Map<String, List<Weather>> groupedByDay = {};
    for (var weather in _forecast!) {
      final dateKey = DateFormat('yyyy-MM-dd').format(weather.date ?? DateTime.now());
      groupedByDay.putIfAbsent(dateKey, () => []).add(weather);
    }

    return Column(
      children: groupedByDay.entries.take(5).map((entry) {
        final date = DateTime.parse(entry.key);
        final weatherList = entry.value;

        // Get midday weather or first available
        final weather = weatherList.firstWhere(
          (w) => (w.date?.hour ?? 0) >= 12,
          orElse: () => weatherList.first,
        );

        // Calculate day's temp range
        final temps = weatherList.map((w) => w.temperature?.celsius ?? 0).toList();
        final minTemp = temps.reduce((a, b) => a < b ? a : b);
        final maxTemp = temps.reduce((a, b) => a > b ? a : b);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: weather.weatherIcon != null
                ? Image.network(
                    _weatherService.getWeatherIconUrl(weather.weatherIcon),
                    width: 50,
                    height: 50,
                  )
                : const Icon(Icons.wb_cloudy, size: 50),
            title: Text(
              DateFormat('EEEE, MMM d').format(date),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(weather.weatherDescription ?? ''),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${maxTemp.round()}°',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${minTemp.round()}°',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
