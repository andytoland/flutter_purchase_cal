import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/purchase.dart';
import 'package:intl/intl.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Purchase>> _purchasesFuture;

  @override
  void initState() {
    super.initState();
    _purchasesFuture = _apiService.getPurchases();
  }

  void _refreshPurchases() {
    setState(() {
      _purchasesFuture = _apiService.getPurchases();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchases'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPurchases,
          ),
        ],
      ),
      body: FutureBuilder<List<Purchase>>(
        future: _purchasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 50),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshPurchases,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No purchases found.'));
          }

          final purchases = snapshot.data!;
          return ListView.builder(
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: Text(purchase.merchant),
                  subtitle: Text(
                    DateFormat('yyyy-MM-dd').format(purchase.date),
                  ),
                  trailing: Text(
                    '\$${purchase.sum.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
