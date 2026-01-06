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
    var types = [HealthDataType.STEPS, HealthDataType.WORKOUT];

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

      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final midnight = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
        final endTime = i == 0 ? now : endOfDay;

        int? steps = await health.getTotalStepsInInterval(midnight, endTime);

        if (steps != null && steps > 0) {
          final dateStr =
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          await apiService.syncSteps(dateStr, steps);
        }
      }

      // Also sync workouts
      await syncWorkouts();

      print("Health sync completed successfully");
    } catch (e) {
      print("Error syncing health data: $e");
    }
  }

  Future<void> syncWorkouts() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Fetch individual workout sessions using named parameters
    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
      types: [HealthDataType.WORKOUT],
      startTime: sevenDaysAgo,
      endTime: now,
    );

    final apiService = ApiService();

    for (var point in healthData) {
      if (point.value is WorkoutHealthValue) {
        WorkoutHealthValue workout = point.value as WorkoutHealthValue;

        // Map activity type to string (e.g., "RUNNING", "WALKING", "YOGA")
        String typeStr = workout.workoutActivityType
            .toString()
            .split('.')
            .last
            .toUpperCase();

        final workoutData = {
          'externalId': point.uuid,
          'type': typeStr,
          'date': point.dateFrom.toIso8601String(),
          'duration': point.dateTo.difference(point.dateFrom).inMinutes,
          'distance': workout.totalDistance,
          'calories': workout.totalEnergyBurned,
        };

        print("Syncing $typeStr workout: ${workoutData['date']}");
        await apiService.syncWorkout(workoutData);
      }
    }
  }
}
