class GCPBilling {
  final double? totalCost;
  final String currency;
  final String accountName;
  final bool isDirect;
  final List<ServiceCost> serviceBreakdown;

  GCPBilling({
    required this.totalCost,
    required this.currency,
    required this.accountName,
    this.isDirect = false,
    required this.serviceBreakdown,
  });

  factory GCPBilling.fromJson(Map<String, dynamic> json) {
    var list = json['serviceBreakdown'] as List? ?? [];
    List<ServiceCost> breakdownList =
        list.map((i) => ServiceCost.fromJson(i)).toList();

    return GCPBilling(
      totalCost: json['totalCost'] as double?,
      currency: json['currency'] ?? 'EUR',
      accountName: json['accountName'] ?? 'Unknown Account',
      isDirect: json['isDirect'] ?? false,
      serviceBreakdown: breakdownList,
    );
  }
}

class ServiceCost {
  final String serviceName;
  final double cost;

  ServiceCost({required this.serviceName, required this.cost});

  factory ServiceCost.fromJson(Map<String, dynamic> json) {
    return ServiceCost(
      serviceName: json['serviceName'] ?? 'Unknown',
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
