class DailyBudget {
  final int id;
  final double sum;
  final double spended;
  final DateTime date;

  DailyBudget({
    required this.id,
    required this.sum,
    required this.spended,
    required this.date,
  });

  factory DailyBudget.fromJson(Map<String, dynamic> json) {
    return DailyBudget(
      id: json['id'],
      sum: double.parse(json['sum'].toString()),
      spended: double.parse(json['spended'].toString()),
      date: DateTime.parse(json['date']),
    );
  }
}
