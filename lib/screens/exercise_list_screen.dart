import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class ExerciseListScreen extends StatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
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
        // Filter for NOT running
        _workouts = workouts.where((w) => w['type'] != 'RUNNING').toList();
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
      appBar: AppBar(title: const Text('Exercise History')),
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
                  ? const Center(child: Text('No exercises found.'))
                  : ListView.builder(
                      itemCount: _workouts.length,
                      itemBuilder: (context, index) {
                        final item = _workouts[index];
                        final date = DateTime.parse(item['date']);
                        final type = item['type'] ?? 'OTHER';
                        final duration = item['duration'] ?? 0;
                        final calories = item['calories'] ?? 0;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.fitness_center,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              '${DateFormat('yyyy-MM-dd HH:mm').format(date)} - $type',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$duration min'),
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
