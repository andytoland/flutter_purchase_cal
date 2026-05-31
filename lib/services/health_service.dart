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
      final dayStart = DateTime.parse(dateStr); // 00:00:00
      final sleepWindowStart = dayStart.subtract(const Duration(hours: 12)); // Day X-1 12:00
      final sleepWindowEnd = dayStart.add(const Duration(hours: 23, minutes: 59));

      print("Fetching health data for $dateStr (Window: $sleepWindowStart to $sleepWindowEnd)");

      // 2. Fetch Sleep Data
      List<HealthDataPoint> sleepData = await health.getHealthDataFromTypes(
        types: [
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_IN_BED,
        ],
        startTime: sleepWindowStart,
        endTime: sleepWindowEnd,
      );

      print("Fetched ${sleepData.length} sleep data points");

      // 3. Filter Sleep
      List<HealthDataPoint> validSleepSegments = [];
      List<HealthDataPoint> asleepSegments = [];
      List<HealthDataPoint> inBedSegments = [];
      int sleepMinutes = 0;

      for (var point in sleepData) {
        // We only care about segments that strictly END on the target day's period (morning of Day X)
        // Or broadly, segments that "belong" to the night leading into Day X.
        // A segment ending at 8am on Day X belongs to Day X.
        // A segment ending at 11pm on Day X-1 belongs to Day X-1 (yesterday).
        // So check: dateTo is on Day X (OR dateTo is late Day X-1?? No, typically we sleep into Day X).
        // Let's stick to "Ends on Day X".
        
         if (point.dateTo.isAfter(dayStart) && point.dateTo.day == dayStart.day) {
             validSleepSegments.add(point);
             if (point.type == HealthDataType.SLEEP_ASLEEP) {
               asleepSegments.add(point);
             } else if (point.type == HealthDataType.SLEEP_IN_BED) {
               inBedSegments.add(point);
             }
         }
      }

      // Calculate Sleep Minutes
      // Prioritize ASLEEP. If ASLEEP exists, sum it.
      // If NO ASLEEP exists (e.g. no Watch), fallback to IN_BED.
      if (asleepSegments.isNotEmpty) {
         for (var seg in asleepSegments) {
            sleepMinutes += seg.dateTo.difference(seg.dateFrom).inMinutes;
         }
      } else if (inBedSegments.isNotEmpty) {
         print("No ASLEEP data found, falling back to IN_BED");
         for (var seg in inBedSegments) {
            sleepMinutes += seg.dateTo.difference(seg.dateFrom).inMinutes;
         }
      }

      print("Calculated sleep minutes: $sleepMinutes (Asleep: ${asleepSegments.length}, InBed: ${inBedSegments.length})");

      // 4. Determine Window for HRV/RHR
      // If we have sleep segments, use their MIN start and MAX end.
      DateTime? filterStart;
      DateTime? filterEnd;

      if (validSleepSegments.isNotEmpty) {
         final starts = validSleepSegments.map((e) => e.dateFrom).toList();
         final ends = validSleepSegments.map((e) => e.dateTo).toList();
         starts.sort((a, b) => a.compareTo(b));
         ends.sort((a, b) => a.compareTo(b));
         filterStart = starts.first;
         filterEnd = ends.last;
         print("Sleep Window Found: $filterStart to $filterEnd");
      } else {
         // Fallback: Assume sleep was 10 PM Day X-1 to 10 AM Day X
         print("No sleep data found, using default Night Window for HRV/RHR");
         filterStart = dayStart.subtract(const Duration(hours: 2)); // 10 PM yesterday
         filterEnd = dayStart.add(const Duration(hours: 10)); // 10 AM today
      }

      // 5. Fetch HRV/RHR for the broad window (fetch slightly wider to be safe)
      List<HealthDataPoint> heartData = await health.getHealthDataFromTypes(
        types: [
          HealthDataType.HEART_RATE_VARIABILITY_SDNN,
          HealthDataType.RESTING_HEART_RATE,
        ],
        startTime: sleepWindowStart,
        endTime: sleepWindowEnd,
      );
      
      print("Fetched ${heartData.length} heart data points");

      List<double> hrvValues = [];
      List<double> rhrValues = [];

      for (var point in heartData) {
         // Filter strictly within our determined "Sleep/Night Window"
         if (point.dateFrom.isAfter(filterStart!.subtract(const Duration(minutes: 1))) && 
             point.dateTo.isBefore(filterEnd!.add(const Duration(minutes: 1)))) {
            
            if (point.type == HealthDataType.HEART_RATE_VARIABILITY_SDNN) {
                final val = point.value as NumericHealthValue;
                hrvValues.add(double.parse(val.numericValue.toString()));
            } else if (point.type == HealthDataType.RESTING_HEART_RATE) {
                final val = point.value as NumericHealthValue;
                rhrValues.add(double.parse(val.numericValue.toString()));
            }
         }
      }

      double? hrv;
      double? rhr;

      if (hrvValues.isNotEmpty) {
        hrv = hrvValues.reduce((a, b) => a + b) / hrvValues.length;
      }
      if (rhrValues.isNotEmpty) {
        rhr = rhrValues.reduce((a, b) => a + b) / rhrValues.length;
      }
      
      print("Final values - Sleep: $sleepMinutes, HRV: $hrv, RHR: $rhr");

      if (hrv != null || rhr != null || sleepMinutes > 0) {
        final healthData = {
          'date': dateStr,
          if (hrv != null) 'hrv': hrv,
          if (rhr != null) 'restingHeartRate': rhr.round(),
          if (sleepMinutes > 0) 'sleepMinutes': sleepMinutes,
        };
        print("Syncing Refined health data for $dateStr: $healthData");
        await apiService.syncDailyHealth(healthData);
      }
    } catch (e, stack) {
      print("Error syncing refined health data for $dateStr: $e");
      print(stack);
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
