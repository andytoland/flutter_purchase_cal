import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/theme_manager.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _googleMapsKeyController =
      TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final url = await _apiService.getBaseUrl();
    final token = await _apiService.getToken();
    final googleMapsKey = await _apiService.getGoogleMapsKey();
    setState(() {
      _urlController.text = url;
      _tokenController.text = token ?? '';
      _googleMapsKeyController.text = googleMapsKey ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _apiService.setBaseUrl(_urlController.text);
    await _apiService.setToken(_tokenController.text);
    await _apiService.setGoogleMapsKey(_googleMapsKeyController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings Saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API Configuration',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      border: OutlineInputBorder(),
                      helperText: 'e.g., https://pc.lightsaber.biz',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'Bearer Token',
                      border: OutlineInputBorder(),
                      helperText: 'Paste your JWT token here',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _googleMapsKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Google Maps API Key',
                      border: OutlineInputBorder(),
                      helperText: 'For map functionality',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 24),
                  const Text(
                    'Appearance',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('App Theme'),
                    subtitle: Text(themeManager.currentTheme.name.toUpperCase()),
                    trailing: DropdownButton<AppTheme>(
                      value: themeManager.currentTheme,
                      onChanged: (AppTheme? newValue) {
                        if (newValue != null) {
                          themeManager.setTheme(newValue);
                          setState(() {});
                        }
                      },
                      items: AppTheme.values.map((AppTheme theme) {
                        return DropdownMenuItem<AppTheme>(
                          value: theme,
                          child: Text(theme.name.split('.').last.replaceAllMapped(
                              RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}').trim().toUpperCase()),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Home Background',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Option for default (None)
                        _buildBgThumbnail(null, 'Theme Default'),
                        _buildBgThumbnail('assets/images/backgrounds/winter_forest.png', 'Winter Forest'),
                        _buildBgThumbnail('assets/images/backgrounds/winter_cabin.png', 'Winter Cabin'),
                        _buildBgThumbnail('assets/images/backgrounds/summer_beach.png', 'Summer Beach'),
                        _buildBgThumbnail('assets/images/backgrounds/summer_field.png', 'Summer Field'),
                        _buildBgThumbnail('assets/images/backgrounds/cyberpunk_city.png', 'Cyberpunk City'),
                        _buildBgThumbnail('assets/images/backgrounds/retro_wave.png', 'Retro Wave'),
                        _buildBgThumbnail('assets/images/backgrounds/modern_skyscraper.png', 'Modern Skyscraper'),
                        _buildBgThumbnail('assets/images/backgrounds/gothic_cathedral.png', 'Gothic Cathedral'),
                        _buildBgThumbnail('assets/images/backgrounds/mountain_lake.png', 'Mountain Lake'),
                        _buildBgThumbnail('assets/images/backgrounds/desert_dunes.png', 'Desert Dunes'),
                        _buildBgThumbnail('assets/images/backgrounds/digital_currency.png', 'Digital Currency'),
                        _buildBgThumbnail('assets/images/backgrounds/trading_floor.png', 'Trading Floor'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Text('Save API Settings'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBgThumbnail(String? path, String label) {
    final isSelected = themeManager.selectedBackgroundImage == path;
    return GestureDetector(
      onTap: () {
        themeManager.setBackgroundImage(path);
        setState(() {});
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: path == null
                    ? Container(
                        color: Colors.grey.withOpacity(0.2),
                        child: const Icon(Icons.block, color: Colors.grey),
                      )
                    : Image.asset(path, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
