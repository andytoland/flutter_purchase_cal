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
  List<dynamic> _healthList = [];
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
      
      final results = await Future.wait([
        _apiService.getDailySteps(dateStr),
        _apiService.getDailyHealth(dateStr),
      ]);

      setState(() {
        _stepsList = results[0];
        _healthList = results[1];
        _isLoading = false;
      });
    } catch (e) {
      // If health fetch fails but steps succeed, we might still want to show steps.
      // But for simplicity, we show error. Or we could try catch individually.
      print("Error fetching health data: $e");
      setState(() {
         // Try to recover steps if possible, but simplest is to show error or empty list
         // If steps succeeded but health failed, we might have partial data
      });
      
      // Retry fetching just steps if bulk failed? 
      // Actually Future.wait fails if any fails.
      // Let's do robust fetching
       try {
          final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
          final steps = await _apiService.getDailySteps(dateStr);
          setState(() {
            _stepsList = steps;
            _error = "Partial Load: $e"; 
            _isLoading = false;
          });
       } catch (e2) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
       }
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
      appBar: AppBar(title: const Text('Daily Health History')),
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
                        final rawDate = item['date'];
                        final date = DateTime.parse(rawDate);
                        final steps = item['steps'] ?? 0;
                        
                        // Find matching health data
                        Map<String, dynamic>? healthItem;
                        try {
                           healthItem = _healthList.firstWhere(
                             (h) => (h['date'] as String).startsWith(rawDate.substring(0, 10)),
                              orElse: () => null,
                           );
                        } catch (e) {
                          // Ignore
                        }

                        final sleepMinutes = healthItem?['sleepMinutes'] as int? ?? 0;
                        final hrv = healthItem?['hrv'] as num?; // float
                        final rhr = healthItem?['restingHeartRate'] as int?;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                     Text(
                                      DateFormat('yyyy-MM-dd').format(date),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                     ),
                                     Row(
                                       children: [
                                         const Icon(Icons.directions_walk, size: 20),
                                         const SizedBox(width: 4),
                                         Text(
                                            NumberFormat('#,###').format(steps),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                         ),
                                       ],
                                     )
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        const Icon(Icons.bed, color: Colors.indigo),
                                        const SizedBox(height: 4),
                                        Text(
                                          sleepMinutes > 0 
                                            ? '${(sleepMinutes / 60).floor()}h ${sleepMinutes % 60}m' 
                                            : '--',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const Text('Sleep', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Icon(Icons.favorite, color: Colors.pink),
                                        const SizedBox(height: 4),
                                        Text(
                                          hrv != null ? '${hrv.toStringAsFixed(0)} ms' : '--',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const Text('HRV', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Icon(Icons.monitor_heart, color: Colors.blue),
                                        const SizedBox(height: 4),
                                        Text(
                                          rhr != null ? '$rhr bpm' : '--',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const Text('RHR', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ],
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
