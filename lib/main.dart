import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'services/health_service.dart';
import 'screens/purchase_list_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/location_add_screen.dart';
import 'screens/payment_type_add_screen.dart';
import 'screens/payment_type_list_screen.dart';
import 'screens/spending_add_screen.dart';
import 'screens/spending_list_screen.dart';
import 'screens/visit_add_screen.dart';
import 'screens/visit_list_screen.dart';
import 'services/api_service.dart';

import 'screens/daily_budget_add_screen.dart';
import 'screens/daily_budget_list_screen.dart';
import 'screens/daily_steps_list_screen.dart';
import 'screens/workout_list_screen.dart';

const String healthSyncTask =
    "com.example.flutter_purchase_calc.healthSyncTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final healthService = HealthService();
    await healthService.syncSteps();
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);

  await Workmanager().registerPeriodicTask(
    "1",
    healthSyncTask,
    frequency: const Duration(hours: 1),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purchase Calc',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initMapKey();
    _syncHealth();
  }

  Future<void> _syncHealth() async {
    final healthService = HealthService();
    await healthService.syncSteps();
  }

  Future<void> _initMapKey() async {
    final apiService = ApiService();
    final key = await apiService.getGoogleMapsKey();
    if (key != null && key.isNotEmpty) {
      await apiService.updateNativeGoogleMapsKey(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Purchase Calc',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Show Purchases'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PurchaseListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_location),
              title: const Text('Add Location'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationAddScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.place),
              title: const Text('Add Visit'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VisitAddScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('List Visits'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VisitListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Add Payment Type'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentTypeAddScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Payment Types'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentTypeListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Add Spending'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SpendingAddScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('Spending List'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SpendingListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_card),
              title: const Text('Add Daily Budget'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailyBudgetAddScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('List Daily Budgets'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailyBudgetListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_walk),
              title: const Text('Daily Steps'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailyStepsListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_run),
              title: const Text('Running History'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkoutListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bull.png',
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.3),
            colorBlendMode: BlendMode.darken,
          ),
          const Center(
            child: Text(
              'Purchase Calc',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(2.0, 2.0),
                    blurRadius: 3.0,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Syncing Health Data...')),
                  );
                  await HealthService().syncSteps();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Step Sync Completed')),
                  );
                },
                icon: const Icon(Icons.sync),
                label: const Text('Sync Health Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
