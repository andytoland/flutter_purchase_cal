import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/payment_type.dart';

class PaymentTypeListScreen extends StatefulWidget {
  const PaymentTypeListScreen({super.key});

  @override
  State<PaymentTypeListScreen> createState() => _PaymentTypeListScreenState();
}

class _PaymentTypeListScreenState extends State<PaymentTypeListScreen> {
  final ApiService _apiService = ApiService();
  List<PaymentType> _paymentTypes = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPaymentTypes();
  }

  Future<void> _fetchPaymentTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getPaymentTypes();
      setState(() {
        _paymentTypes = data.map((json) => PaymentType.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePaymentType(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Type'),
        content: const Text(
          'Are you sure you want to delete this payment type?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isActionLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiService.deletePaymentType(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment type deleted!')));

      setState(() {
        _paymentTypes.removeWhere((pt) => pt.id == id);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isActionLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Types')),
      body: Column(
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _paymentTypes.isEmpty
                ? const Center(child: Text('No payment types found.'))
                : ListView.builder(
                    itemCount: _paymentTypes.length,
                    itemBuilder: (context, index) {
                      final pt = _paymentTypes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(pt.paymenttype),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _isActionLoading
                                ? null
                                : () => _deletePaymentType(pt.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
