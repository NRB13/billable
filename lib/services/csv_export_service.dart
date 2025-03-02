import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/time_entry.dart';

class CsvExportService {
  static final CsvExportService _instance = CsvExportService._internal();

  factory CsvExportService() => _instance;

  CsvExportService._internal();

  // Headers for the Jaris CSV format
  List<String> get jarisHeaders => [
    'Date',
    'Client',
    'Project',
    'Task',
    'Hours',
    'Notes',
    'Billable?',
    'Invoice Number',
    'Rate',
    'Amount'
  ];

  // Generate CSV string from time entries
  String generateCsvString(List<TimeEntry> entries) {
    // Prepare the data rows
    List<List<dynamic>> rows = [jarisHeaders];
    
    // Add time entries
    for (var entry in entries) {
      rows.add(entry.toJarisCsvRow());
    }
    
    // Convert to CSV
    return const ListToCsvConverter().convert(rows);
  }

  // Save CSV to file and return the file path
  Future<String> saveCsvToFile(List<TimeEntry> entries) async {
    // Generate CSV string
    String csvData = generateCsvString(entries);
    
    // Define file path
    final directory = await getApplicationDocumentsDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '${directory.path}/jaris_timesheet_$dateStr.csv';
    
    // Write to file
    final File file = File(path);
    await file.writeAsString(csvData);
    
    return path;
  }

  // Export CSV and share
  Future<void> exportAndShareCsv(List<TimeEntry> entries) async {
    final filePath = await saveCsvToFile(entries);
    final file = XFile(filePath);
    
    // Share the file
    await Share.shareXFiles(
      [file],
      subject: 'Jaris Timesheet Export',
      text: 'Here is your timesheet export for Jaris.',
    );
  }

  // Export CSV to a specific directory
  Future<String> exportCsvToDirectory(
      List<TimeEntry> entries, String directory) async {
    // Generate CSV string
    String csvData = generateCsvString(entries);
    
    // Define file path
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '$directory/jaris_timesheet_$dateStr.csv';
    
    // Write to file
    final File file = File(path);
    await file.writeAsString(csvData);
    
    return path;
  }
}
