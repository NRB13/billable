import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../providers/settings_provider.dart';
import '../constants/app_constants.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY'];
  bool _isExporting = false;
  bool _isImporting = false;
  
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              // Appearance settings
              _buildSectionHeader('Appearance'),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme throughout the app'),
                value: settings.isDarkMode,
                onChanged: (value) {
                  settings.toggleDarkMode();
                },
              ),
              const Divider(),
              
              // Time tracking settings
              _buildSectionHeader('Time Tracking'),
              ListTile(
                title: const Text('Default Currency'),
                subtitle: Text(settings.defaultCurrency),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showCurrencyPicker(context, settings),
              ),
              const Divider(),
              ListTile(
                title: const Text('Default Hours Per Day'),
                subtitle: Text('${settings.defaultHoursPerDay} hours'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showHoursPerDayPicker(context, settings),
              ),
              const Divider(),
              
              // Data management
              _buildSectionHeader('Data Management'),
              SwitchListTile(
                title: const Text('Auto Backup'),
                subtitle: const Text('Automatically backup data daily'),
                value: settings.autoBackup,
                onChanged: (value) {
                  settings.toggleAutoBackup();
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Export Database'),
                subtitle: const Text('Create a backup of your data'),
                trailing: const Icon(Icons.download, size: 20),
                onTap: _isExporting ? null : () => _exportDatabase(context),
              ),
              const Divider(),
              ListTile(
                title: const Text('Import Database'),
                subtitle: const Text('Restore from a backup'),
                trailing: const Icon(Icons.upload, size: 20),
                onTap: _isImporting ? null : () => _importDatabase(context),
              ),
              const Divider(),
              
              // About section
              _buildSectionHeader('About'),
              ListTile(
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
              ),
              const Divider(),
            ],
          ),
          if (_isExporting || _isImporting)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                          _isExporting 
                              ? 'Exporting database...' 
                              : 'Importing database...',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }
  
  void _showCurrencyPicker(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _currencies.length,
              itemBuilder: (context, index) {
                final currency = _currencies[index];
                return ListTile(
                  title: Text(currency),
                  trailing: currency == settings.defaultCurrency
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    settings.setDefaultCurrency(currency);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  void _showHoursPerDayPicker(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(
      text: settings.defaultHoursPerDay.toString(),
    );
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Default Hours Per Day'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Hours',
              hintText: 'Enter default hours per day',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final hours = int.tryParse(controller.text);
                if (hours != null && hours > 0 && hours <= 24) {
                  settings.setDefaultHoursPerDay(hours);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid number between 1 and 24'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _exportDatabase(BuildContext context) async {
    if (!mounted) return;
    setState(() => _isExporting = true);
    
    try {
      final dbService = DatabaseService();
      final dbFile = await dbService.getDatabaseFile();
      
      if (!mounted) {
        return;
      }
      
      // Share the file
      await Share.shareXFiles(
        [XFile(dbFile.path)],
        subject: 'Billable Database Backup',
        text: 'Billable time tracking database backup',
      );
      
      if (!mounted) {
        return;
      }
      
      // Using context.mounted for BuildContext
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database exported successfully')),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting database: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
  
  Future<void> _importDatabase(BuildContext context) async {
    if (!mounted) return;
    setState(() => _isImporting = true);
    
    try {
      // Show warning dialog
      bool? confirm;
      if (context.mounted) {
        confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Warning'),
            content: const Text(
              'Importing a database will replace all your current data. '
              'This cannot be undone. Are you sure you want to continue?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Import'),
              ),
            ],
          ),
        );
      }
      
      if (!mounted || confirm != true) {
        if (mounted) {
          setState(() => _isImporting = false);
        }
        return;
      }
      
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );
      
      if (!mounted) {
        return;
      }
      
      if (result == null || result.files.single.path == null) {
        setState(() => _isImporting = false);
        return;
      }
      
      final filePath = result.files.single.path!;
      
      // Import the database
      final dbService = DatabaseService();
      await dbService.importDatabase(File(filePath));
      
      if (!mounted) {
        return;
      }
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database imported successfully. Restarting app...')),
        );
      }
      
      // Give time for the snackbar to show before restarting
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted && context.mounted) {
        // Restart the app (by popping back to home and refreshing)
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing database: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }
}
