class Spending {
  final int id;
  final double sum;
  final DateTime date;
  final String
  locationName; // It seems the API might return nested object or just name, React code handles both but flat name is easier for table
  final String paymentType;

  Spending({
    required this.id,
    required this.sum,
    required this.date,
    required this.locationName,
    required this.paymentType,
  });

  factory Spending.fromJson(Map<String, dynamic> json) {
    String locName = '';
    if (json['locationName'] != null) {
      locName = json['locationName'];
    } else if (json['location'] != null && json['location'] is Map) {
      locName = json['location']['name'] ?? '';
    }

    return Spending(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      sum: json['sum'] is double
          ? json['sum']
          : double.parse(json['sum'].toString()),
      date: DateTime.parse(json['date']),
      locationName: locName,
      paymentType: json['paymenttype'] ?? '',
    );
  }
}
