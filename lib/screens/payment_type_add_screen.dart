import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PaymentTypeAddScreen extends StatefulWidget {
  const PaymentTypeAddScreen({super.key});

  @override
  State<PaymentTypeAddScreen> createState() => _PaymentTypeAddScreenState();
}

class _PaymentTypeAddScreenState extends State<PaymentTypeAddScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _paymentTypeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _paymentTypeController.dispose();
    super.dispose();
  }

  Future<void> _addPaymentType() async {
    final paymentType = _paymentTypeController.text.trim();
    if (paymentType.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _apiService.addPaymentType(paymentType);

      setState(() {
        _successMessage = 'Payment type added!';
        _paymentTypeController.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Payment Type')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _paymentTypeController,
              decoration: const InputDecoration(
                labelText: 'Payment Type',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _addPaymentType,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 20),
              Text(
                _successMessage!,
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
