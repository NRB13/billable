import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_constants.dart';
import '../models/time_entry.dart';
import '../providers/time_entry_provider.dart';
import '../services/csv_export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isExporting = false;
  List<TimeEntry> _entriesToExport = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final timeEntryProvider =
        Provider.of<TimeEntryProvider>(context, listen: false);
    final entries = await timeEntryProvider.getNonSubmittedEntriesInDateRange(
      _startDate,
      _endDate,
    );

    setState(() {
      _entriesToExport = entries;
    });
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate;
        }
      });
      _loadEntries();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      _loadEntries();
    }
  }

  Future<void> _exportToCsv() async {
    setState(() {
      _isExporting = true;
    });

    try {
      if (_entriesToExport.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No entries found for the selected date range'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final csvExportService = CsvExportService();
      final filePath = await csvExportService.saveCsvToFile(_entriesToExport);

      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Time Entries Export',
      );

      // Ask if user wants to mark entries as submitted
      if (!mounted) return;

      // Store context in local variable to avoid async gap issue
      final shouldMarkAsSubmitted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mark as Submitted?'),
          content:
              const Text('Would you like to mark these entries as submitted? '
                  'This helps prevent exporting the same entries twice.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (shouldMarkAsSubmitted == true) {
        if (!mounted) return;

        final timeEntryProvider =
            Provider.of<TimeEntryProvider>(context, listen: false);
        final entryIds = _entriesToExport.map((e) => e.id!).toList();
        await timeEntryProvider.markEntriesAsSubmitted(entryIds);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entries marked as submitted'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        // Refresh the list of entries
        _loadEntries();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Time Entries'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    // Display current month/year range
                    Text(
                      '${_monthYearFormat.format(_startDate)} - ${_monthYearFormat.format(_endDate)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectStartDate(context),
                            child: InputDecorator(
                              decoration: AppConstants.inputDecoration(
                                'Start Date',
                                'Select start date',
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_dateFormat.format(_startDate)),
                                  const Icon(Icons.calendar_today),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingMd),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectEndDate(context),
                            child: InputDecorator(
                              decoration: AppConstants.inputDecoration(
                                'End Date',
                                'Select end date',
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_dateFormat.format(_endDate)),
                                  const Icon(Icons.calendar_today),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isExporting ? null : _exportToCsv,
                        style: AppConstants.primaryButtonStyle,
                        child: _isExporting
                            ? const CupertinoActivityIndicator(
                                color: Colors.white)
                            : const Text('Export to CSV'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entries to Export (${_entriesToExport.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingSm),
                      Expanded(
                        child: _entriesToExport.isEmpty
                            ? const Center(
                                child:
                                    Text('No entries in selected date range'),
                              )
                            : ListView.builder(
                                itemCount: _entriesToExport.length,
                                itemBuilder: (context, index) {
                                  final entry = _entriesToExport[index];
                                  return ListTile(
                                    title: Text(
                                        '${entry.clientName} - ${entry.projectName}'),
                                    subtitle: Text(entry.taskName),
                                    trailing: Text(
                                        '${entry.hours.toStringAsFixed(2)} hrs'),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
