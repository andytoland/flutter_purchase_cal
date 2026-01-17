import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import '../services/gcp_billing_service.dart';
import '../models/gcp_billing.dart';

class GCPBillingScreen extends StatefulWidget {
  const GCPBillingScreen({super.key});

  @override
  State<GCPBillingScreen> createState() => _GCPBillingScreenState();
}

class _GCPBillingScreenState extends State<GCPBillingScreen> {
  final ApiService _apiService = ApiService();
  final GCPBillingService _gcpService = GCPBillingService();
  GCPBilling? _billingData;
  bool _isLoading = true;
  String? _errorMessage;
  String? _billingAccountId;
  GoogleSignInAccount? _googleAccount;

  @override
  void initState() {
    super.initState();
    _checkSignIn();
  }

  Future<void> _checkSignIn() async {
    _googleAccount = await _gcpService.signInSilently();
    if (_googleAccount != null) {
      _fetchBilling();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    final account = await _gcpService.signIn();
    if (account != null) {
      setState(() {
        _googleAccount = account;
      });
      _fetchBilling();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBilling() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final id = await _apiService.getBillingAccountId();
      if (id == null || id.isEmpty) {
        setState(() {
          _errorMessage = "Billing Account ID not set in Settings.";
          _isLoading = false;
        });
        return;
      }
      _billingAccountId = id;

      // Use the direct GCP service instead of the backend proxy
      final data = await _gcpService.fetchBillingInfo(id);
      setState(() {
        _billingData = GCPBilling.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _launchGCPConsole() async {
    final url = Uri.parse('https://console.cloud.google.com/billing/${_billingAccountId ?? ""}');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch GCP Console')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GCP Billing'),
        actions: [
          if (_googleAccount != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchBilling,
            ),
          if (_googleAccount != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _gcpService.signOut();
                setState(() {
                  _googleAccount = null;
                  _billingData = null;
                });
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_googleAccount == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Sign in with Google to view billing data',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleSignIn,
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchBilling,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_billingData == null) {
      return const Center(child: Text('No billing data available.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalCostCard(),
          const SizedBox(height: 24),
          const Text(
            'Service Breakdown',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildBreakdownList(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _launchGCPConsole,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open GCP Console'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCostCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Total Cost (Current Month)',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (_billingData!.totalCost != null)
              Text(
                '${_billingData!.totalCost!.toStringAsFixed(2)} ${_billingData!.currency}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Column(
                children: const [
                  Text(
                    'N/A',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cost data is currently unavailable',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  )
                ],
              ),
            if (_billingData!.isDirect) ...[
              const SizedBox(height: 8),
              const Text(
                '(Direct API limits may apply)',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownList() {
    if (_billingData!.serviceBreakdown.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text('No service breakdown available.')),
      );
    }

    return Column(
      children: _billingData!.serviceBreakdown.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.cloud_queue, color: Colors.blue),
            title: Text(item.serviceName),
            trailing: Text(
              '${item.cost.toStringAsFixed(2)} ${_billingData!.currency}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}
