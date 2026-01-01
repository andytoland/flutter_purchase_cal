import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_budget.dart';
import '../services/api_service.dart';

class DailyBudgetListScreen extends StatefulWidget {
  const DailyBudgetListScreen({super.key});

  @override
  State<DailyBudgetListScreen> createState() => _DailyBudgetListScreenState();
}

class _DailyBudgetListScreenState extends State<DailyBudgetListScreen> {
  final ApiService _apiService = ApiService();
  List<DailyBudget> _budgets = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchBudgets();
  }

  Future<void> _fetchBudgets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getDailyBudgets(_startDate);
      setState(() {
        _budgets = data.map((json) => DailyBudget.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
      _fetchBudgets();
    }
  }

  Future<void> _deleteBudget(int id) async {
    try {
      await _apiService.deleteDailyBudget(id);
      setState(() {
        _budgets.removeWhere((b) => b.id == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Budget deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete budget: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Budgets')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'From Date: ${DateFormat('yyyy-MM-dd').format(_startDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Change Date'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text('Error: $_errorMessage'))
                : _budgets.isEmpty
                ? const Center(child: Text('No budgets found.'))
                : ListView.builder(
                    itemCount: _budgets.length,
                    itemBuilder: (context, index) {
                      final budget = _budgets[index];
                      final percentage = budget.sum == 0
                          ? 0
                          : (budget.spended / budget.sum) * 100;
                      final isOverBudget = percentage > 100;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(budget.date),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sum: ${budget.sum.toStringAsFixed(2)}',
                                    ),
                                    Text(
                                      'Spended: ${budget.spended.toStringAsFixed(2)}',
                                    ),
                                    Text(
                                      'Used: ${percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: isOverBudget
                                            ? Colors.red
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Budget'),
                                    content: const Text(
                                      'Are you sure you want to delete this budget?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteBudget(budget.id);
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
