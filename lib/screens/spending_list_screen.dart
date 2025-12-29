import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/spending.dart';

class SpendingListScreen extends StatefulWidget {
  const SpendingListScreen({super.key});

  @override
  State<SpendingListScreen> createState() => _SpendingListScreenState();
}

class _SpendingListScreenState extends State<SpendingListScreen> {
  final ApiService _apiService = ApiService();
  List<Spending> _spendings = [];

  late DateTime _startDate;
  late DateTime _endDate;

  bool _isLoading = true;
  String? _errorMessage;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    // Default dates: Start = 30 days ago, End = Tomorrow
    final now = DateTime.now();
    _startDate = now.subtract(const Duration(days: 30));
    _endDate = now.add(const Duration(days: 1));

    _fetchSpendings();
  }

  Future<void> _fetchSpendings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);

      final data = await _apiService.getSpendings(
        startDate: startStr,
        endDate: endStr,
      );

      setState(() {
        _spendings = data.map((json) => Spending.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSpending(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Spending'),
        content: const Text('Are you sure you want to delete this spending?'),
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
      await _apiService.deleteSpending(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Spending deleted!')));

      setState(() {
        _spendings.removeWhere((s) => s.id == id);
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

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final totalSum = _spendings.fold<double>(
      0,
      (prev, element) => prev + element.sum,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Spending List')),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(context, true),
                    child: Text(
                      'Start: ${dateFormat.format(_startDate)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(context, false),
                    child: Text(
                      'End: ${dateFormat.format(_endDate)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _fetchSpendings,
                  child: const Text('Filter'),
                ),
              ],
            ),
          ),

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
                : _spendings.isEmpty
                ? const Center(child: Text('No spendings found.'))
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Location')),
                                DataColumn(label: Text('Payment')),
                                DataColumn(label: Text('Sum'), numeric: true),
                                DataColumn(label: Text('Action')),
                              ],
                              rows: _spendings.map((s) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(dateFormat.format(s.date))),
                                    DataCell(Text(s.locationName)),
                                    DataCell(Text(s.paymentType)),
                                    DataCell(Text(s.sum.toStringAsFixed(2))),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: _isActionLoading
                                            ? null
                                            : () => _deleteSpending(s.id),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        color: Colors.grey[200],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              totalSum.toStringAsFixed(2),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
