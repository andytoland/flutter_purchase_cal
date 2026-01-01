import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/purchase.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final Dio _dio = Dio();
  final Dio _externalDio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _baseUrlKey = 'api_base_url';
  static const String _tokenKey = 'auth_token';
  static const String _googleMapsKey = 'google_maps_key';

  // Default URL for Android Emulator is 10.0.2.2 to access localhost
  // For iOS/Web it is localhost. Since we are targeting web/chrome, localhost is fine.
  final String _defaultBaseUrl = 'https://pc.lightsaber.biz';

  ApiService._internal() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<String> getBaseUrl() async {
    String? storedUrl = await _storage.read(key: _baseUrlKey);
    return storedUrl ?? _defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    await _storage.write(key: _baseUrlKey, value: url);
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> setGoogleMapsKey(String key) async {
    await _storage.write(key: _googleMapsKey, value: key);
    await updateNativeGoogleMapsKey(key);
  }

  Future<String?> getGoogleMapsKey() async {
    return await _storage.read(key: _googleMapsKey);
  }

  static const MethodChannel _mapChannel = MethodChannel(
    'com.example.flutter_purchase_calc/maps',
  );

  Future<void> updateNativeGoogleMapsKey(String key) async {
    if (!Platform.isIOS)
      return; // Only iOS supports dynamic key setting this way for now

    try {
      await _mapChannel.invokeMethod('setGoogleMapsApiKey', {'key': key});
    } on PlatformException catch (e) {
      print("Failed to set map key: '${e.message}'.");
    }
  }

  Future<List<Purchase>> getPurchases({
    String? startDate,
    String? endDate,
    String? origin,
  }) async {
    try {
      final baseUrl = await getBaseUrl();
      final queryParams = <String, String>{};
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }
      if (origin != null && origin.isNotEmpty) {
        queryParams['origin'] = origin;
      }

      final uri = Uri.parse(
        '$baseUrl/purchase/get',
      ).replace(queryParameters: queryParams);

      final response = await _dio.getUri(uri);

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Purchase.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load purchases. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching purchases: $e');
    }
  }

  // Location Methods
  Future<List<dynamic>> getLocations() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await _dio.get('$baseUrl/location/list');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to load locations. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching locations: $e');
    }
  }

  Future<void> addLocation(
    String name, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final baseUrl = await getBaseUrl();
      final Map<String, dynamic> data = {'name': name};
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;

      final response = await _dio.post('$baseUrl/location/add', data: data);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to add location. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error adding location: $e');
    }
  }

  Future<void> deleteLocation(int id) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await _dio.post(
        '$baseUrl/location/delete',
        data: {'id': id},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to delete location. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting location: $e');
    }
  }

  // Payment Type Methods
  Future<void> addPaymentType(String paymentType) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await _dio.post(
        '$baseUrl/paymenttype/add',
        data: {'paymenttype': paymentType},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to add payment type. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error adding payment type: $e');
    }
  }

  Future<List<dynamic>> getPaymentTypes() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await _dio.get('$baseUrl/paymenttype/list');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to load payment types. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching payment types: $e');
    }
  }

  Future<void> deletePaymentType(int id) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await _dio.post(
        '$baseUrl/paymenttype/delete',
        data: {'id': id},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to delete payment type. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting payment type: $e');
    }
  }

  // Spending Methods
  Future<void> addSpending(
    double sum,
    String location,
    String paymentType,
  ) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await _dio.post(
        '$baseUrl/spending/add',
        data: {'sum': sum, 'location': location, 'paymenttype': paymentType},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to add spending. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error adding spending: $e');
    }
  }

  Future<List<dynamic>> getSpendings({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final baseUrl = await getBaseUrl();
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse(
        '$baseUrl/spending/list',
      ).replace(queryParameters: queryParams);
      final response = await _dio.getUri(uri);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to load spendings. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching spendings: $e');
    }
  }

  Future<void> deleteSpending(int id) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await _dio.post(
        '$baseUrl/spending/delete',
        data: {'id': id},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to delete spending. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting spending: $e');
    }
  }

  // Visit Methods
  Future<void> addVisit(int locationId, String description) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await _dio.post(
        '$baseUrl/visits/add',
        data: {'locationId': locationId, 'description': description},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to add visit. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error adding visit: $e');
    }
  }

  Future<List<dynamic>> getVisits({String? startDate, String? endDate}) async {
    try {
      final baseUrl = await getBaseUrl();
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse(
        '$baseUrl/visits/list',
      ).replace(queryParameters: queryParams);
      final response = await _dio.getUri(uri);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to load visits. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching visits: $e');
    }
  }

  Future<void> deleteVisit(int id) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await _dio.post(
        '$baseUrl/visits/delete',
        data: {'id': id},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to delete visit. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting visit: $e');
    }
  }

  // Google Places API
  Future<List<dynamic>> searchNearbyPlaces(
    String keyword,
    double lat,
    double lng,
  ) async {
    try {
      final apiKey = await getGoogleMapsKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Google Maps API Key not set');
      }

      final response = await _externalDio.get(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
        queryParameters: {
          'location': '$lat,$lng',
          'rankby': 'distance', // Sort strictly by distance
          'keyword': keyword,
          'key': apiKey,
          // 'radius': '5000', // Cannot specify radius when rankby=distance
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          return data['results'];
        } else {
          throw Exception(
            'Places API Error: ${data['status']} - ${data['error_message'] ?? ''}',
          );
        }
      } else {
        throw Exception(
          'Failed to search places. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error searching places: $e');
    }
  }

  // Daily Budget Methods
  Future<void> addDailyBudget(double sum, DateTime date) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await _dio.post(
        '$baseUrl/dailybudget/create',
        data: {'sum': sum, 'time': date.toIso8601String()},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to add daily budget. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error adding daily budget: $e');
    }
  }

  Future<List<dynamic>> getDailyBudgets(DateTime date) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await _dio.post(
        '$baseUrl/dailybudget/listbudget',
        data: {'date': date.toIso8601String()},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to load daily budgets. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching daily budgets: $e');
    }
  }

  Future<void> deleteDailyBudget(int id) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await _dio.post(
        '$baseUrl/dailybudget/delete',
        data: {'id': id},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to delete daily budget. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting daily budget: $e');
    }
  }
}
