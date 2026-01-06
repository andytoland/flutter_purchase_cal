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
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 30));

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
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final workouts = await _apiService.getWorkouts(dateStr);
      setState(() {
        _workouts = workouts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Running History')),
      body: Column(
        children: [
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
                        final distance =
                            (item['distance'] ?? 0) / 1000; // Convert to km
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
