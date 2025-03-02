import 'package:flutter/foundation.dart';
import '../models/time_entry.dart';
import '../services/database_service.dart';

class TimeEntryProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<TimeEntry> _timeEntries = [];
  bool _isLoading = true;

  List<TimeEntry> get timeEntries => _timeEntries;
  bool get isLoading => _isLoading;

  // Initialize and load time entries
  TimeEntryProvider() {
    _loadTimeEntries();
  }

  Future<void> _loadTimeEntries() async {
    _isLoading = true;
    notifyListeners();
    
    _timeEntries = await _databaseService.getAllTimeEntries();
    
    _isLoading = false;
    notifyListeners();
  }

  // Refresh time entries from database
  Future<void> refreshTimeEntries() async {
    await _loadTimeEntries();
  }

  // Add a new time entry
  Future<void> addTimeEntry(TimeEntry entry) async {
    final id = await _databaseService.insertTimeEntry(entry);
    final newEntry = entry.copyWith(id: id);
    _timeEntries.add(newEntry);
    notifyListeners();
  }

  // Update an existing time entry
  Future<void> updateTimeEntry(TimeEntry entry) async {
    await _databaseService.updateTimeEntry(entry);
    final index = _timeEntries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _timeEntries[index] = entry;
      notifyListeners();
    }
  }

  // Delete a time entry
  Future<void> deleteTimeEntry(int id) async {
    await _databaseService.deleteTimeEntry(id);
    _timeEntries.removeWhere((entry) => entry.id == id);
    notifyListeners();
  }

  // Get non-submitted entries in a date range
  Future<List<TimeEntry>> getNonSubmittedEntriesInDateRange(
      DateTime startDate, DateTime endDate) async {
    return await _databaseService.getNonSubmittedTimeEntriesInDateRange(
        startDate, endDate);
  }

  // Mark entries as submitted
  Future<void> markEntriesAsSubmitted(List<int> ids) async {
    await _databaseService.markEntriesAsSubmitted(ids);
    
    // Update local list
    for (var id in ids) {
      final index = _timeEntries.indexWhere((entry) => entry.id == id);
      if (index != -1) {
        _timeEntries[index] = _timeEntries[index].copyWith(isSubmitted: true);
      }
    }
    
    notifyListeners();
  }

  // Get total hours for the current month
  Future<double> getTotalHoursForMonth(int month, int year) async {
    DateTime startDate = DateTime(year, month, 1);
    DateTime endDate = DateTime(year, month + 1, 0); // Last day of month
    
    final entries = await _databaseService.getTimeEntriesInDateRange(
        startDate, endDate);
    
    double total = 0.0;
    for (var entry in entries) {
      total += entry.hours;
    }
    return total;
  }

  // Get total hours for the current quarter
  Future<double> getTotalHoursForQuarter(int quarter, int year) async {
    double result = await _databaseService.getTotalHoursForQuarter(quarter, year);
    return result;
  }

  // Get total hours for the current year
  Future<double> getTotalHoursForYear(int year) async {
    DateTime startDate = DateTime(year, 1, 1);
    DateTime endDate = DateTime(year, 12, 31);
    
    final entries = await _databaseService.getTimeEntriesInDateRange(
        startDate, endDate);
    
    double total = 0.0;
    for (var entry in entries) {
      total += entry.hours;
    }
    return total;
  }

  // Get a list of all clients
  Future<List<String>> getAllClients() async {
    return await _databaseService.getAllClients();
  }

  // Get total hours for a specific client
  Future<double> getTotalHoursForClient(String clientName) async {
    return await _databaseService.getTotalHoursForClient(clientName);
  }
  
  // Get all projects
  Future<List<String>> getAllProjects() async {
    return await _databaseService.getAllProjects();
  }
  
  // Get total hours by project
  Future<Map<String, double>> getTotalHoursByProject() async {
    return await _databaseService.getTotalHoursByProject();
  }
  
  // Get hours by day of week
  Future<Map<String, double>> getHoursByDayOfWeek() async {
    return await _databaseService.getHoursByDayOfWeek();
  }
  
  // Get average daily hours by month
  Future<Map<String, double>> getAverageDailyHoursByMonth() async {
    return await _databaseService.getAverageDailyHoursByMonth();
  }
  
  // Get billable vs non-billable hours
  Future<Map<String, double>> getBillableVsNonBillableHours() async {
    return await _databaseService.getBillableVsNonBillableHours();
  }
  
  // Get most time-consuming tasks
  Future<List<Map<String, dynamic>>> getMostTimeConsumingTasks(int limit) async {
    return await _databaseService.getMostTimeConsumingTasks(limit);
  }
  
  // Get productivity metrics
  Future<Map<String, dynamic>> getProductivityMetrics() async {
    return await _databaseService.getProductivityMetrics();
  }
}
