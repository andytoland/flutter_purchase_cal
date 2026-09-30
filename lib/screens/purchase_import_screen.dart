import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Uploads a bank statement export (Aktia HTML/CSV, Nordea or S-Pankki CSV)
/// to the backend, which parses it into purchases.
class PurchaseImportScreen extends StatefulWidget {
  const PurchaseImportScreen({super.key});

  @override
  State<PurchaseImportScreen> createState() => _PurchaseImportScreenState();
}

class _PurchaseImportScreenState extends State<PurchaseImportScreen> {
  final ApiService _apiService = ApiService();

  static const List<String> _bankOptions = ['auto', 'aktia', 'nordea', 'spankki'];

  String _bank = 'auto';
  PlatformFile? _file;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  /// Reads the picked file, trying strict UTF-8 first and falling back to
  /// Latin-1, since Finnish bank CSV exports are typically Latin-1 encoded.
  String _decodeBytes(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'html', 'htm'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _file = result.files.first;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  Future<void> _import() async {
    if (_file == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await _apiService.importPurchases(
        content: _decodeBytes(_file!.bytes!),
        bank: _bank,
        filename: _file!.name,
      );

      final imported = result['imported'] ?? 0;
      final parsed = result['parsed'] ?? 0;
      final duplicates = result['duplicates'] ?? 0;
      final bank = result['bank'] ?? _bank;

      setState(() {
        _successMessage = 'Imported $imported of $parsed rows from $bank'
            '${duplicates > 0 ? ' ($duplicates duplicates skipped)' : ''}';
        _file = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Bank Statement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _bank,
              decoration: const InputDecoration(
                labelText: 'Bank',
                border: OutlineInputBorder(),
                isDense: true,
                helperText: 'Auto detects the format (Aktia CSV/HTML, Nordea, S-Pankki)',
              ),
              items: _bankOptions
                  .map((bank) => DropdownMenuItem(
                        value: bank,
                        child: Text(bank == 'auto' ? 'Auto-detect' : bank),
                      ))
                  .toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _bank = value);
                      }
                    },
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(_file?.name ?? 'Choose CSV file'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading || _file == null ? null : _import,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Import'),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_successMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _successMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
