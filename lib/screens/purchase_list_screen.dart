import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/purchase.dart';
import 'package:intl/intl.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  final ApiService _apiService = ApiService();

  // Data State
  List<Purchase> _purchases = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter State
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _originController = TextEditingController();
  bool _showFilters = false;

  // Sort State
  int _sortColumnIndex = 1; // Default to Date
  bool _sortAscending = false; // Default to Descending (newest first)

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
  }

  @override
  void dispose() {
    _originController.dispose();
    super.dispose();
  }

  Future<void> _fetchPurchases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final startDateStr = _startDate != null
          ? DateFormat('yyyy-MM-dd').format(_startDate!)
          : null;
      final endDateStr = _endDate != null
          ? DateFormat('yyyy-MM-dd').format(_endDate!)
          : null;

      final data = await _apiService.getPurchases(
        startDate: startDateStr,
        endDate: endDateStr,
        origin: _originController.text,
      );

      setState(() {
        _purchases = data;
        _isLoading = false;
        _sortPurchases(); // Apply current sort
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _sortPurchases() {
    if (_purchases.isEmpty) return;

    _purchases.sort((a, b) {
      int comparison = 0;
      switch (_sortColumnIndex) {
        case 0: // ID
          comparison = a.id.compareTo(b.id);
          break;
        case 1: // Date
          comparison = a.date.compareTo(b.date);
          break;
        case 2: // Merchant
          comparison = a.merchant.toLowerCase().compareTo(
            b.merchant.toLowerCase(),
          );
          break;
        case 3: // Sum
          comparison = a.sum.compareTo(b.sum);
          break;
        case 4: // Origin
          comparison = a.origin.toLowerCase().compareTo(b.origin.toLowerCase());
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortPurchases();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _originController.clear();
    });
    _fetchPurchases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchases'),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPurchases,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorView()
                : _buildDataTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _startDate == null
                          ? 'Start Date'
                          : dateFormat.format(_startDate!),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _endDate == null
                          ? 'End Date'
                          : dateFormat.format(_endDate!),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _originController,
                    decoration: const InputDecoration(
                      labelText: 'Origin',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _fetchPurchases,
                  child: const Text('Filter'),
                ),
              ],
            ),
            if (_startDate != null ||
                _endDate != null ||
                _originController.text.isNotEmpty)
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear Filters'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          Text(
            'Error: $_errorMessage',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchPurchases,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (_purchases.isEmpty) {
      return const Center(child: Text('No purchases found.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          columns: [
            DataColumn(label: const Text('ID'), numeric: true, onSort: _onSort),
            DataColumn(label: const Text('Date'), onSort: _onSort),
            DataColumn(label: const Text('Merchant'), onSort: _onSort),
            DataColumn(
              label: const Text('Sum'),
              numeric: true,
              onSort: _onSort,
            ),
            DataColumn(label: const Text('Origin'), onSort: _onSort),
          ],
          rows: _purchases.map((purchase) {
            return DataRow(
              cells: [
                DataCell(Text(purchase.id.toString())),
                DataCell(Text(DateFormat('yyyy-MM-dd').format(purchase.date))),
                DataCell(Text(purchase.merchant)),
                DataCell(Text(purchase.sum.toStringAsFixed(2))),
                DataCell(Text(purchase.origin)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
