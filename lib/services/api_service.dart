import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/purchase.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _baseUrlKey = 'api_base_url';
  static const String _tokenKey = 'auth_token';

  // Default URL for Android Emulator is 10.0.2.2 to access localhost
  // For iOS/Web it is localhost. Since we are targeting web/chrome, localhost is fine.
  final String _defaultBaseUrl = 'http://localhost:8080';

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

  Future<List<Purchase>> getPurchases() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await _dio.get('$baseUrl/purchase/get');

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
}
