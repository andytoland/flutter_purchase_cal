import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/todo.dart';
import 'package:intl/intl.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _taskController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<Todo> _todos = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTodos();
  }

  Future<void> _fetchTodos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final todos = await _apiService.getTodos();
      if (mounted) {
        setState(() {
          _todos = todos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addTodo() async {
    if (_taskController.text.isEmpty) return;

    setState(() {
      _isActionLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiService.addTodo(_taskController.text, _selectedDate);
      _taskController.clear();
      await _fetchTodos();
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

  Future<void> _deleteTodo(int id) async {
    setState(() {
      _isActionLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiService.deleteTodo(id);
      setState(() {
        _todos.removeWhere((t) => t.id == id);
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

  Future<void> _toggleTodo(int id) async {
    try {
      await _apiService.toggleTodo(id);
      await _fetchTodos();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('To Do List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(
                    labelText: 'New Task',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Due Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _selectDate(context),
                      child: const Text('Select Date'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isActionLoading ? null : _addTodo,
                      child: const Text('Add'),
                    ),
                  ],
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
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _todos.isEmpty
                    ? const Center(child: Text('No tasks found.'))
                    : ListView.builder(
                        itemCount: _todos.length,
                        itemBuilder: (context, index) {
                          final todo = _todos[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                value: todo.isCompleted,
                                onChanged: (value) => _toggleTodo(todo.id),
                              ),
                              title: Text(
                                todo.task,
                                style: TextStyle(
                                  decoration: todo.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Text(
                                'Due: ${DateFormat('yyyy-MM-dd').format(todo.dueDate)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: _isActionLoading
                                    ? null
                                    : () => _deleteTodo(todo.id),
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
