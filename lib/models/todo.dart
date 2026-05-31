class Todo {
  final int id;
  final String task;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  Todo({
    required this.id,
    required this.task,
    required this.dueDate,
    required this.isCompleted,
    required this.createdAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      task: json['task'],
      dueDate: DateTime.parse(json['dueDate']),
      isCompleted: json['isCompleted'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task': task,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
