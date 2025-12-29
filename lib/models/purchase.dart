class Purchase {
  final int id;
  final DateTime date;
  final double sum;
  final String merchant;
  final String origin;
  final DateTime createDate;
  final String? type;

  Purchase({
    required this.id,
    required this.date,
    required this.sum,
    required this.merchant,
    required this.origin,
    required this.createDate,
    this.type,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      date: DateTime.parse(json['date']),
      sum: double.tryParse(json['sum'].toString()) ?? 0.0,
      merchant: json['merchant'],
      origin: json['origin'],
      createDate: DateTime.parse(json['createDate']),
      type: json['type'],
    );
  }
}
