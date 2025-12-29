class PaymentType {
  final int id;
  final String paymenttype;

  PaymentType({required this.id, required this.paymenttype});

  factory PaymentType.fromJson(Map<String, dynamic> json) {
    return PaymentType(
      id: int.parse(json['id'].toString()),
      paymenttype: json['paymenttype'],
    );
  }
}
