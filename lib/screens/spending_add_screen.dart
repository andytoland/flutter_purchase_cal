import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/location.dart';
import '../models/payment_type.dart';

class SpendingAddScreen extends StatefulWidget {
  const SpendingAddScreen({super.key});

  @override
  State<SpendingAddScreen> createState() => _SpendingAddScreenState();
}

class _SpendingAddScreenState extends State<SpendingAddScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _sumController = TextEditingController();

  List<Location> _locations = [];
  List<PaymentType> _paymentTypes = [];

  String? _selectedLocationName;
  String? _selectedPaymentType;

  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _sumController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locData = await _apiService.getLocations();
      final ptData = await _apiService.getPaymentTypes();

      setState(() {
        _locations = locData.map((json) => Location.fromJson(json)).toList();
        _paymentTypes = ptData
            .map((json) => PaymentType.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addSpending() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocationName == null || _selectedPaymentType == null) {
      setState(() {
        _errorMessage = 'Please select location and payment type';
      });
      return;
    }

    final sum = double.tryParse(_sumController.text);
    if (sum == null) {
      setState(() {
        _errorMessage = 'Invalid sum';
      });
      return;
    }

    setState(() {
      _isActionLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _apiService.addSpending(
        sum,
        _selectedLocationName!,
        _selectedPaymentType!,
      );
      setState(() {
        _successMessage = 'Spending added!';
        _sumController.clear();
        // Reset selections if desired, or keep them for faster multiple entries
        // _selectedLocationName = null;
        // _selectedPaymentType = null;
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
      appBar: AppBar(title: const Text('Add Spending')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _sumController,
                      decoration: const InputDecoration(
                        labelText: 'Sum',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      // Replace commas with dots immediately on typing
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final newText = newValue.text.replaceAll(',', '.');
                          return newValue.copyWith(
                            text: newText,
                            selection: newValue.selection,
                          );
                        }),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a sum';
                        }
                        // tryParse handles the dot we ensured nicely
                        if (double.tryParse(value.replaceAll(',', '.')) ==
                            null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedLocationName,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                      items: _locations.map((loc) {
                        return DropdownMenuItem(
                          value: loc.name,
                          child: Text(loc.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLocationName = value;
                        });
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentType,
                      decoration: const InputDecoration(
                        labelText: 'Payment Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _paymentTypes.map((pt) {
                        return DropdownMenuItem(
                          value: pt.paymenttype,
                          child: Text(pt.paymenttype),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentType = value;
                        });
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isActionLoading ? null : _addSpending,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isActionLoading
                          ? const CircularProgressIndicator()
                          : const Text('Add Spending'),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_successMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
