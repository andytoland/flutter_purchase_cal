import 'package:health/health.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health health = Health();

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    var types = [HealthDataType.STEPS];

    bool? hasPermission = await health.hasPermissions(types);
    if (hasPermission == true) return true;

    return await health.requestAuthorization(types);
  }

  Future<void> syncSteps() async {
    if (kIsWeb) return;

    try {
      bool hasPermission = await requestPermissions();
      if (!hasPermission) {
        print("Health permissions not granted");
        return;
      }

      final apiService = ApiService();
      final now = DateTime.now();

      // Sync the last 7 days to ensure no data is missed
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final midnight = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

        // For today, we only fetch up to "now"
        final endTime = i == 0 ? now : endOfDay;

        int? steps = await health.getTotalStepsInInterval(midnight, endTime);

        if (steps != null && steps > 0) {
          final dateStr =
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          print("Syncing $steps steps for $dateStr");
          await apiService.syncSteps(dateStr, steps);
        }
      }
      print("Health sync completed successfully for last 7 days");
    } catch (e) {
      print("Error syncing health data: $e");
    }
  }
}
