import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/location.dart';
import '../services/notification_service.dart';

class VisitAddScreen extends StatefulWidget {
  const VisitAddScreen({super.key});

  @override
  State<VisitAddScreen> createState() => _VisitAddScreenState();
}

class _VisitAddScreenState extends State<VisitAddScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _descriptionController = TextEditingController();

  List<Location> _locations = [];
  int? _selectedLocationId;

  bool _isLoadingLocations = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocations() async {
    // 1. Try Cache
    try {
      final cachedLocs = await _apiService.getCachedLocations();
      if (mounted && cachedLocs != null) {
        setState(() {
          _locations = cachedLocs.map((json) => Location.fromJson(json)).toList();
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      print("Cache error: $e");
    }

    // 2. Fetch Network
    try {
      final data = await _apiService.getLocations();
      if (mounted) {
        setState(() {
          _locations = data.map((json) => Location.fromJson(json)).toList();
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      if (mounted && _locations.isEmpty) {
        setState(() {
          _errorMessage = 'Failed to load locations: $e';
          _isLoadingLocations = false;
        });
      }
    }
  }

  Future<void> _saveVisit() async {
    if (_selectedLocationId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a location')));
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _apiService.addVisit(
        _selectedLocationId!,
        _descriptionController.text,
      );

      // Suppress notifications for the rest of today and cancel any shown
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await prefs.setString('visit_suppressed_date', today);
      await NotificationService().cancelAll();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit recorded successfully!')),
      );
      // Reset form
      setState(() {
        _selectedLocationId = null;
        _descriptionController.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Visit')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add a Visit',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Record your visit to a location with an optional description.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Select Location',
                border: OutlineInputBorder(),
              ),
              value: _selectedLocationId,
              items: _locations.map((loc) {
                return DropdownMenuItem<int>(
                  value: loc.id,
                  child: Text(loc.name),
                );
              }).toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _selectedLocationId = value;
                      });
                    },
              hint: _isLoadingLocations
                  ? const Text('Loading locations...')
                  : const Text('Select a location'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving || _isLoadingLocations ? null : _saveVisit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Visit'),
            ),
          ],
        ),
      ),
    );
  }
}
