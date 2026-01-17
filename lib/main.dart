import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
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
import 'screens/exercise_list_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'models/location.dart' as model;
import 'theme/theme_manager.dart';

final themeManager = ThemeManager();

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
    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, _) {
        return MaterialApp(
          title: 'Purchase Calc',
          theme: themeManager.getThemeData(),
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _todaySteps = 0;
  double _todaySpent = 0.0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _initMapKey();
    _syncHealth();
  }

  Future<void> _fetchTodayData() async {
    setState(() => _isLoadingStats = true);
    final apiService = ApiService();
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);

    print("--- Fetching Today's Data ($dateStr) ---");

    // 1. Load from Cache first for immediate UI feedback
    try {
      final cachedSteps = await apiService.getCachedDailySteps(dateStr);
      if (cachedSteps != null) {
        _processStepsData(cachedSteps, dateStr);
        print("Steps loaded from cache");
      }

      final startDate = now.subtract(const Duration(days: 2));
      final endDate = now.add(const Duration(days: 1));
      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);

      final cachedSpending = await apiService.getCachedSpendings(
        startDate: startStr,
        endDate: endStr,
      );
      if (cachedSpending != null) {
        _processSpendingData(cachedSpending, now);
        print("Spending loaded from cache");
      }
    } catch (e) {
      print("Error loading cached data: $e");
    }

    // 2. Fetch from Network
    try {
      // Steps
      apiService.getDailySteps(dateStr).then((stepsData) {
        _processStepsData(stepsData, dateStr);
        print("Steps fetched from network");
      }).catchError((e) {
        print("Error fetching network steps: $e");
      });

      // Spending
      final startDate = now.subtract(const Duration(days: 2));
      final endDate = now.add(const Duration(days: 1));
      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);

      apiService.getSpendings(startDate: startStr, endDate: endStr).then((spendingData) {
        _processSpendingData(spendingData, now);
        print("Spending fetched from network");
      }).catchError((e) {
        print("Error fetching network spending: $e");
      }).whenComplete(() {
        if (mounted) {
          setState(() => _isLoadingStats = false);
          print("--- Fetch Today's Data Finished ---");
        }
      });

    } catch (e) {
      print("Error starting network fetches: $e");
      setState(() => _isLoadingStats = false);
    }
  }

  void _processStepsData(List<dynamic> stepsData, String dateStr) {
    if (!mounted) return;
    if (stepsData.isNotEmpty) {
      final todayEntry = stepsData.firstWhere(
        (e) => (e['date'] as String).startsWith(dateStr),
        orElse: () => null,
      );
      if (todayEntry != null) {
        setState(() {
          _todaySteps = int.parse(todayEntry['steps'].toString());
        });
      }
    }
  }

  void _processSpendingData(List<dynamic> spendingData, DateTime now) {
    if (!mounted) return;
    double total = 0;
    for (var s in spendingData) {
      final rawDate = s['date'] as String;
      final sum = double.tryParse(s['sum'].toString()) ?? 0.0;
      final date = DateTime.parse(rawDate).toLocal();

      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      if (isToday) {
        total += sum;
      }
    }
    setState(() {
      _todaySpent = total;
    });
  }

  Future<void> _quickLocationAction(Function(model.Location) onLocationSelected) async {
    // 1. Check/Request Geolocation Permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return;
      }
    }

    setState(() => _isLoadingStats = true);
    try {
      // 2. Get Current Position
      final position = await Geolocator.getCurrentPosition();

      // 3. Get Locations
      final apiService = ApiService();
      final List<dynamic> locData = await apiService.getLocations();
      final locations = locData.map((json) => model.Location.fromJson(json)).toList();

      // 4. Filter and Sort
      List<Map<String, dynamic>> nearby = [];
      List<model.Location> others = [];

      for (var loc in locations) {
        if (loc.latitude != null && loc.longitude != null) {
          double distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            loc.latitude!,
            loc.longitude!,
          );
          if (distance <= 200) {
            nearby.add({'location': loc, 'distance': distance});
          } else {
            others.add(loc);
          }
        } else {
          others.add(loc);
        }
      }

      nearby.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      others.sort((a, b) => a.name.compareTo(b.name));

      // 5. Show Selection UI
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  nearby.isNotEmpty ? 'Places Nearby' : 'All Places',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: [
                      if (nearby.isNotEmpty) ...[
                        ...nearby.map((n) {
                          final loc = n['location'] as model.Location;
                          final dist = n['distance'] as double;
                          return ListTile(
                            leading: const Icon(Icons.location_on, color: Colors.green),
                            title: Text(loc.name),
                            subtitle: Text('${dist.toStringAsFixed(0)} meters away'),
                            onTap: () {
                              Navigator.pop(context);
                              onLocationSelected(loc);
                            },
                          );
                        }),
                        const Divider(),
                        const Text('Other Places', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                      ...others.map((loc) => ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(loc.name),
                            onTap: () {
                              Navigator.pop(context);
                              onLocationSelected(loc);
                            },
                          )),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print("Error in location action: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _quickAddVisit() async {
    await _quickLocationAction((loc) => _submitVisit(loc.id, loc.name));
  }

  Future<void> _quickAddSpending() async {
    await _quickLocationAction((loc) => _promptForSum(loc));
  }

  Future<void> _promptForSum(model.Location loc) async {
    final TextEditingController sumController = TextEditingController();
    final apiService = ApiService();
    
    // 1. Fetch Payment Types
    List<dynamic> ptData = await apiService.getCachedPaymentTypes() ?? [];
    if (ptData.isEmpty) {
      ptData = await apiService.getPaymentTypes();
    }
    
    String? selectedPT = ptData.isNotEmpty ? ptData.first['paymenttype'] as String : 'Bank card';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Spent at ${loc.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: sumController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (€)',
                      hintText: '0.00',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPT,
                    decoration: const InputDecoration(labelText: 'Payment Type'),
                    items: ptData.map((pt) {
                      final name = pt['paymenttype'] as String;
                      return DropdownMenuItem(value: name, child: Text(name));
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedPT = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(sumController.text.replaceAll(',', '.'));
                    if (val != null && val > 0) {
                      Navigator.pop(context, {'sum': val, 'paymentType': selectedPT});
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      _submitSpending(loc.name, result['sum'], result['paymentType']);
    }
  }

  Future<void> _submitSpending(String locationName, double sum, String paymentType) async {
    setState(() => _isLoadingStats = true);
    try {
      final apiService = ApiService();
      await apiService.addSpending(sum, locationName, paymentType);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added $sum € spent at $locationName ($paymentType)')),
        );
        _fetchTodayData(); // Refresh stats
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add spending: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _submitVisit(int locationId, String locationName) async {
    setState(() => _isLoadingStats = true);
    try {
      final apiService = ApiService();
      await apiService.addVisit(locationId, 'Quick visit from home screen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Visit to $locationName recorded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record visit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _syncHealth() async {
    final healthService = HealthService();
    await healthService.syncSteps();
    await _fetchTodayData();
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
        title: const Text('Purchase Calc'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Theme.of(context).appBarTheme.foregroundColor,
                  fontSize: 24,
                ),
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
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SpendingAddScreen(),
                  ),
                );
                _fetchTodayData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('Spending List'),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SpendingListScreen(),
                  ),
                );
                _fetchTodayData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_card),
              title: const Text('Add Daily Budget'),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailyBudgetAddScreen(),
                  ),
                );
                _fetchTodayData();
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
              leading: const Icon(Icons.fitness_center),
              title: const Text('Exercise History'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExerciseListScreen(),
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
      body: ListenableBuilder(
        listenable: themeManager,
        builder: (context, _) {
          final theme = themeManager.currentTheme;
          final customBg = themeManager.selectedBackgroundImage;
          // Identify light themes
          final isDark = theme != AppTheme.light && 
                        theme != AppTheme.softBlueLush &&
                        theme != AppTheme.lavenderMist &&
                        theme != AppTheme.sageGarden &&
                        theme != AppTheme.sandyBeach &&
                        theme != AppTheme.minimalWhite;
          final textColor = isDark ? Colors.white : Colors.black87;
          final containerColor = isDark 
              ? Colors.black.withOpacity(0.2) 
              : Colors.white.withOpacity(0.3);

          return Stack(
            fit: StackFit.expand,
            children: [
              if (customBg != null)
                Image.asset(
                  customBg,
                  fit: BoxFit.cover,
                  color: isDark ? Colors.black.withOpacity(0.2) : null,
                  colorBlendMode: isDark ? BlendMode.darken : null,
                )
              else if (theme == AppTheme.originalDark)
                Image.asset(
                  'assets/images/bull.png',
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.3),
                  colorBlendMode: BlendMode.darken,
                )
              else if (theme == AppTheme.modernDark)
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                    ),
                  ),
                )
              else
                Container(color: Theme.of(context).scaffoldBackgroundColor),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoadingStats)
                      CircularProgressIndicator(color: textColor)
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: containerColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.directions_walk,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Steps: $_todaySteps',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.attach_money, color: Colors.green),
                                const SizedBox(width: 10),
                                Text(
                                  'Spent: ${_todaySpent.toStringAsFixed(2)} €',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _quickAddVisit,
                                  icon: const Icon(Icons.add_location_alt),
                                  label: const Text('Add Visit'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? Colors.white.withOpacity(0.2) : Colors.blueGrey.withOpacity(0.1),
                                    foregroundColor: textColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: _quickAddSpending,
                                  icon: const Icon(Icons.add_shopping_cart),
                                  label: const Text('Add Spending'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? Colors.white.withOpacity(0.2) : Colors.blueGrey.withOpacity(0.1),
                                    foregroundColor: textColor,
                                  ),
                                ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
                      await _fetchTodayData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Step Sync Completed')),
                        );
                      }
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Health Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white.withOpacity(0.2) : Colors.blueGrey.withOpacity(0.1),
                      foregroundColor: textColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
