class GCPBilling {
  final double totalCost;
  final String currency;
  final List<GCPServiceCost> serviceBreakdown;

  GCPBilling({
    required this.totalCost,
    required this.currency,
    required this.serviceBreakdown,
  });

  factory GCPBilling.fromJson(Map<String, dynamic> json) {
    return GCPBilling(
      totalCost: (json['totalCost'] ?? 0).toDouble(),
      currency: json['currency'] ?? '€',
      serviceBreakdown: (json['serviceBreakdown'] as List? ?? [])
          .map((item) => GCPServiceCost.fromJson(item))
          .toList(),
    );
  }
}

class GCPServiceCost {
  final String serviceName;
  final double cost;

  GCPServiceCost({
    required this.serviceName,
    required this.cost,
  });

  factory GCPServiceCost.fromJson(Map<String, dynamic> json) {
    return GCPServiceCost(
      serviceName: json['serviceName'] ?? 'Unknown',
      cost: (json['cost'] ?? 0).toDouble(),
    );
  }
}
