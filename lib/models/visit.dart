class Visit {
  final int id;
  final DateTime date;
  final String description;
  final String locationName;

  Visit({
    required this.id,
    required this.date,
    required this.description,
    required this.locationName,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    String locName = '';
    if (json['location'] != null && json['location'] is Map) {
      locName = json['location']['name'] ?? '';
    } else if (json['locationName'] != null) {
      locName = json['locationName'];
    }

    return Visit(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      date: DateTime.parse(json['date']),
      description: json['description'] ?? '',
      locationName: locName,
    );
  }
}
