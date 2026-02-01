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
    
    // Configure Health Connect on Android
    await health.configure();

    var types = [
      HealthDataType.STEPS,
      HealthDataType.WORKOUT,
      HealthDataType.HEART_RATE_VARIABILITY_SDNN,
      HealthDataType.RESTING_HEART_RATE,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.SLEEP_AWAKE,
    ];

    // Check Health Connect availability on Android
    if (defaultTargetPlatform == TargetPlatform.android) {
        HealthConnectSdkStatus? status = await health.getHealthConnectSdkStatus();
        if (status == HealthConnectSdkStatus.sdkUnavailable) {
            print("Health Connect SDK is unavailable. Prompting to install.");
             // Try to install/update Health Connect
            await health.installHealthConnect();
            return false;
        }
        if (status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
            print("Health Connect SDK provider update required. Prompting to install/update.");
            await health.installHealthConnect();
            return false;
        }
    }

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
        final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        // 1. Sync Steps
        int? steps = await health.getTotalStepsInInterval(midnight, endTime);
        if (steps != null && steps > 0) {
          await apiService.syncSteps(dateStr, steps);
        }

        // 2. Sync Other Health Data (Sleep, HRV, RHR)
        await _syncOtherHealthData(apiService, midnight, endTime, dateStr);
      }

      // Also sync workouts
      await syncWorkouts();

      print("Health sync completed successfully");
    } catch (e) {
      print("Error syncing health data: $e");
    }
  }

  Future<void> _syncOtherHealthData(
      ApiService apiService, DateTime start, DateTime end, String dateStr) async {
    try {
      // Fetch Health Data
      List<HealthDataPoint> data = await health.getHealthDataFromTypes(
        types: [
          HealthDataType.HEART_RATE_VARIABILITY_SDNN,
          HealthDataType.RESTING_HEART_RATE,
          HealthDataType.SLEEP_ASLEEP,
        ],
        startTime: start,
        endTime: end,
      );

      double? hrv;
      double? rhr;
      int sleepMinutes = 0;

      List<double> hrvValues = [];
      List<double> rhrValues = [];

      for (var point in data) {
        if (point.type == HealthDataType.HEART_RATE_VARIABILITY_SDNN) {
           final val = point.value as NumericHealthValue;
           hrvValues.add(double.parse(val.numericValue.toString()));
        } else if (point.type == HealthDataType.RESTING_HEART_RATE) {
           final val = point.value as NumericHealthValue;
           rhrValues.add(double.parse(val.numericValue.toString()));
        } else if (point.type == HealthDataType.SLEEP_ASLEEP) {
           sleepMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
        }
      }

      if (hrvValues.isNotEmpty) {
        hrv = hrvValues.reduce((a, b) => a + b) / hrvValues.length;
      }
      if (rhrValues.isNotEmpty) {
        rhr = rhrValues.reduce((a, b) => a + b) / rhrValues.length;
      }

      if (hrv != null || rhr != null || sleepMinutes > 0) {
        final healthData = {
          'date': dateStr,
          if (hrv != null) 'hrv': hrv,
          if (rhr != null) 'restingHeartRate': rhr.round(),
          if (sleepMinutes > 0) 'sleepMinutes': sleepMinutes,
        };
        print("Syncing health data for $dateStr: $healthData");
        await apiService.syncDailyHealth(healthData);
      }
    } catch (e) {
      print("Error syncing other health data for $dateStr: $e");
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
