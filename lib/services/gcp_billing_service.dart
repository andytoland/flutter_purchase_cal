import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/cloudbilling/v1.dart';
import 'package:http/http.dart' as http;

class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class GCPBillingService {
  static final GCPBillingService _instance = GCPBillingService._internal();
  factory GCPBillingService() => _instance;
  GCPBillingService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/cloud-billing.readonly',
      'https://www.googleapis.com/auth/cloud-platform',
    ],
  );

  GoogleSignInAccount? _currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser;
    } catch (error) {
      print('Google Sign-In error: $error');
      return null;
    }
  }

  Future<void> signOut() => _googleSignIn.disconnect();

  Future<GoogleSignInAccount?> signInSilently() async {
    _currentUser = await _googleSignIn.signInSilently();
    return _currentUser;
  }

  Future<CloudbillingApi?> getBillingApi() async {
    final account = _currentUser ?? await signInSilently();
    if (account == null) return null;

    final authHeaders = await account.authHeaders;
    final httpClient = GoogleHttpClient(authHeaders);
    return CloudbillingApi(httpClient);
  }

  Future<http.Client?> getAuthenticatedClient() async {
    final account = _currentUser ?? await signInSilently();
    if (account == null) return null;
    final authHeaders = await account.authHeaders;
    return GoogleHttpClient(authHeaders);
  }

  Future<Map<String, dynamic>> fetchBillingInfo(String billingAccountId) async {
    final billingApi = await getBillingApi();
    final client = await getAuthenticatedClient();
    
    if (billingApi == null || client == null) {
      throw Exception('Not authenticated with Google');
    }

    try {
      // 1. Get Account Info
      final account = await billingApi.billingAccounts.get('billingAccounts/$billingAccountId');
      
      // 2. Get Budgets via Raw HTTP (since wrapper is missing calculatedSpend)
      final budgetsUrl = Uri.parse(
        'https://billingbudgets.googleapis.com/v1/billingAccounts/$billingAccountId/budgets'
      );
      
      print('VERSION_CHECK: Fetching with detail logic');
      print('Fetching budgets from: $budgetsUrl');
      final response = await client.get(budgetsUrl);
      print('Budgets API Status: ${response.statusCode}');
      print('Budgets API Response: ${response.body}');
      
      double? totalCost;
      String currency = '€'; // Default

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> budgets = jsonResponse['budgets'] ?? [];

        if (budgets.isNotEmpty) {
          // Use the first budget found
          final firstBudget = budgets.first;
          final String budgetName = firstBudget['name'];
          
          // FETCH INDIVIDUAL BUDGET (The list view often omits calculatedSpend)
          final budgetDetailUrl = Uri.parse(
            'https://billingbudgets.googleapis.com/v1/$budgetName'
          );
          print('Fetching budget detail: $budgetDetailUrl');
          final detailResponse = await client.get(budgetDetailUrl);
          print('Budget Detail Status: ${detailResponse.statusCode}');
          print('Budget Detail Body: ${detailResponse.body}');

          if (detailResponse.statusCode == 200) {
            final budgetDetail = json.decode(detailResponse.body);
            
            // Navigate to: calculatedSpend -> actualSpend -> amount
            final calculatedSpend = budgetDetail['calculatedSpend'];
            final actualSpend = calculatedSpend?['actualSpend'];
            final amount = actualSpend?['amount'];
            
            if (amount != null) {
               final units = int.tryParse(amount['units']?.toString() ?? '0') ?? 0;
               final nanos = int.tryParse(amount['nanos']?.toString() ?? '0') ?? 0;
               totalCost = (units + (nanos / 1000000000.0));
            } else {
              print('Warning: calculatedSpend field is missing in budget detail.');
            }
          }
           currency = account.currencyCode ?? '€';
        }
      } else {
        print('Failed to fetch budgets: ${response.statusCode} ${response.body}');
      }

      return {
        'totalCost': totalCost, // Nullable
        'currency': currency,
        'accountName': account.displayName ?? 'Unknown',
        'isDirect': true,
        'serviceBreakdown': [], 
      };
    } catch (e) {
      print('Error fetching GCP billing: $e');
      rethrow;
    }
  }
}
