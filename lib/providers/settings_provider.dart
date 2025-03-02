import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  String _defaultCurrency = 'USD';
  int _defaultHoursPerDay = 8;
  bool _autoBackup = false;
  
  // Getters
  bool get isDarkMode => _isDarkMode;
  String get defaultCurrency => _defaultCurrency;
  int get defaultHoursPerDay => _defaultHoursPerDay;
  bool get autoBackup => _autoBackup;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      final dbService = DatabaseService();
      final settings = await dbService.getSettings();
      
      _isDarkMode = settings['dark_mode'] == 1;
      _defaultCurrency = settings['default_currency'] ?? 'USD';
      _defaultHoursPerDay = settings['default_hours_per_day'] ?? 8;
      _autoBackup = settings['auto_backup'] == 1;
      
      if (kDebugMode) {
        debugPrint('Settings loaded successfully');
        debugPrint('Dark mode: $_isDarkMode');
        debugPrint('Default currency: $_defaultCurrency');
        debugPrint('Default hours per day: $_defaultHoursPerDay');
        debugPrint('Auto backup: $_autoBackup');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading settings: $e');
        debugPrint('Using default settings');
      }
      // Use defaults
      _isDarkMode = false;
      _defaultCurrency = 'USD';
      _defaultHoursPerDay = 8;
      _autoBackup = false;
    } finally {
      notifyListeners();
    }
  }
  
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _saveSettings('dark_mode', _isDarkMode ? 1 : 0);
    notifyListeners();
  }
  
  Future<void> setDefaultCurrency(String currency) async {
    _defaultCurrency = currency;
    await _saveSettings('default_currency', currency);
    notifyListeners();
  }
  
  Future<void> setDefaultHoursPerDay(int hours) async {
    _defaultHoursPerDay = hours;
    await _saveSettings('default_hours_per_day', hours);
    notifyListeners();
  }
  
  Future<void> toggleAutoBackup() async {
    _autoBackup = !_autoBackup;
    await _saveSettings('auto_backup', _autoBackup ? 1 : 0);
    notifyListeners();
  }
  
  Future<void> _saveSettings(String key, dynamic value) async {
    try {
      final dbService = DatabaseService();
      await dbService.saveSetting(key, value);
      if (kDebugMode) {
        debugPrint('Saved setting $key: $value');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving setting $key: $e');
      }
    }
  }
}
