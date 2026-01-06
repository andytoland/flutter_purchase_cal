import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _workouts = [];
  bool _isLoading = true;
  String _error = '';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 11));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchWorkouts();
  }

  Future<void> _fetchWorkouts() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
      final workouts = await _apiService.getWorkouts(startStr, endDate: endStr);
      setState(() {
        _workouts = workouts.where((w) => w['type'] == 'RUNNING').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
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
      _fetchWorkouts();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      _fetchWorkouts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Running History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () => _selectStartDate(context),
                        child: Text(
                          'From: ${DateFormat('yyyy-MM-dd').format(_startDate)}',
                        ),
                      ),
                      TextButton(
                        onPressed: () => _selectEndDate(context),
                        child: Text(
                          'To: ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchWorkouts,
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
              child: _workouts.isEmpty
                  ? const Center(child: Text('No running sessions found.'))
                  : ListView.builder(
                      itemCount: _workouts.length,
                      itemBuilder: (context, index) {
                        final item = _workouts[index];
                        final date = DateTime.parse(item['date']);
                        final distance = (item['distance'] ?? 0) / 1000;
                        final duration = item['duration'] ?? 0;
                        final calories = item['calories'] ?? 0;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Icon(
                                Icons.directions_run,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(date),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${distance.toStringAsFixed(2)} km  •  $duration min',
                                ),
                                if (item['info'] != null &&
                                    (item['info'] as String).isNotEmpty)
                                  Text(
                                    item['info'],
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Text('${calories.toInt()} kcal'),
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
