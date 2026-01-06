import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class DailyStepsListScreen extends StatefulWidget {
  const DailyStepsListScreen({super.key});

  @override
  State<DailyStepsListScreen> createState() => _DailyStepsListScreenState();
}

class _DailyStepsListScreenState extends State<DailyStepsListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _stepsList = [];
  bool _isLoading = true;
  String _error = '';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchSteps();
  }

  Future<void> _fetchSteps() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final steps = await _apiService.getDailySteps(dateStr);
      setState(() {
        _stepsList = steps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchSteps();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Steps History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'From: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
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
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error.isNotEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          else
            Expanded(
              child: _stepsList.isEmpty
                  ? const Center(child: Text('No steps found.'))
                  : ListView.builder(
                      itemCount: _stepsList.length,
                      itemBuilder: (context, index) {
                        final item = _stepsList[index];
                        final date = DateTime.parse(item['date']);
                        final steps = item['steps'] ?? 0;
                        return ListTile(
                          title: Text(DateFormat('yyyy-MM-dd').format(date)),
                          trailing: Text(
                            NumberFormat('#,###').format(steps),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          leading: const Icon(Icons.directions_walk),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
