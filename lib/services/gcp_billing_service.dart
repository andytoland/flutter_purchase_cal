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

  Future<Map<String, dynamic>> fetchBillingInfo(String billingAccountId) async {
    final api = await getBillingApi();
    if (api == null) throw Exception('Not authenticated with Google');

    try {
      // Note: Cloud Billing API v1 doesn't have a direct "current spend" endpoint 
      // without extra setup (like Budgets or BigQuery).
      // We will fetch the Billing Account details to verify access.
      final account = await api.billingAccounts.get('billingAccounts/$billingAccountId');
      
      // Since we can't get "amount so far" easily via direct REST (non-export),
      // we will return the account name and a placeholder note for the costs.
      // In a real production app, one would likely use the Budgets API or a Cloud Function proxy.
      
      return {
        'totalCost': 0.0, // Placeholder
        'currency': '€',
        'accountName': account.displayName ?? 'Unknown',
        'isDirect': true,
      };
    } catch (e) {
      print('Error fetching GCP billing: $e');
      rethrow;
    }
  }
}
