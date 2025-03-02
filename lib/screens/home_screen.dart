import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../models/time_entry.dart';
import '../providers/time_entry_provider.dart';
import 'time_entry_form_screen.dart';
import 'export_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  DateTime _selectedMonth = DateTime.now();
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    _refreshEntries();
  }

  void _refreshEntries() {
    Provider.of<TimeEntryProvider>(context, listen: false).refreshTimeEntries();
  }

  Future<void> _navigateToAddEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TimeEntryFormScreen(),
      ),
    );

    if (result == true) {
      _refreshEntries();
    }
  }

  void _showMonthPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      setState(() {
                        _isFiltering = true;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedMonth,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _selectedMonth = DateTime(newDate.year, newDate.month, 1);
                    });
                  },
                  minimumDate: DateTime(2020),
                  maximumDate: DateTime(2030),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearFilter() {
    setState(() {
      _isFiltering = false;
      _selectedMonth = DateTime.now();
    });
  }

  Future<void> _confirmDelete(TimeEntry entry) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Entry'),
          content: Text('Are you sure you want to delete this entry for ${entry.clientName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<TimeEntryProvider>(context, listen: false)
                    .deleteTimeEntry(entry.id!);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Clock Icon for Time Tracking
            const Icon(Icons.timer_outlined, size: 24),
            const SizedBox(width: 10),
            // App Name with Subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Billable',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Time Tracking & Metrics',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha(230), // ~0.9 opacity
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insert_chart_outlined),
            tooltip: 'Statistics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatisticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Export',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExportScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
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
      body: Column(
        children: [
          // Filter bar - modernized
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
              vertical: AppConstants.spacingSm,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13), // ~0.05 opacity
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showMonthPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingMd,
                        vertical: AppConstants.spacingSm,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[700] : Colors.white,
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isFiltering
                                ? _monthYearFormat.format(_selectedMonth)
                                : 'All Entries',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isFiltering)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear filter',
                    onPressed: _clearFilter,
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                  onPressed: _refreshEntries,
                ),
              ],
            ),
          ),
          
          // Time entries list
          Expanded(
            child: Consumer<TimeEntryProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                    ),
                  );
                }

                if (provider.timeEntries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 64,
                          color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No time entries yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first one with the + button',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter entries if necessary
                List<TimeEntry> displayedEntries = provider.timeEntries;
                if (_isFiltering) {
                  final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                  displayedEntries = displayedEntries
                      .where((entry) =>
                          entry.date.isAfter(_selectedMonth.subtract(const Duration(days: 1))) &&
                          entry.date.isBefore(nextMonth))
                      .toList();
                }

                // Sort by date, most recent first
                displayedEntries.sort((a, b) => b.date.compareTo(a.date));

                if (displayedEntries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 48,
                          color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No entries for ${_monthYearFormat.format(_selectedMonth)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount: displayedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = displayedEntries[index];
                    return Dismissible(
                      key: Key('entry-${entry.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red[400],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMd,
                          vertical: AppConstants.spacingSm,
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24.0),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        await _confirmDelete(entry);
                        return false; // We handle deletion in the confirm dialog
                      },
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMd,
                          vertical: AppConstants.spacingSm,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppConstants.spacingMd),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row with client-project and hours
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Client-Project
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${entry.clientName} - ${entry.taskName}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          entry.projectName,
                                          style: TextStyle(
                                            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Hours
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? AppConstants.primaryColor.withAlpha(51) // ~0.2 opacity
                                          : AppConstants.primaryColor.withAlpha(25), // ~0.1 opacity
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${entry.hours} hrs',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? AppConstants.primaryColor.withAlpha(230) // ~0.9 opacity
                                            : AppConstants.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Date and status indicators
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Date
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _dateFormat.format(entry.date),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Status indicators
                                  Row(
                                    children: [
                                      // Billable indicator
                                      if (entry.isBillable)
                                        Tooltip(
                                          message: 'Billable',
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withAlpha(25), // ~0.1 opacity
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.attach_money,
                                                  size: 14,
                                                  color: Colors.green[700],
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else
                                        Tooltip(
                                          message: 'Non-billable',
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withAlpha(25), // ~0.1 opacity
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.money_off,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      
                                      const SizedBox(width: 8),
                                      
                                      // Submitted indicator
                                      if (entry.isSubmitted)
                                        Tooltip(
                                          message: 'Submitted',
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withAlpha(25), // ~0.1 opacity
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_circle_outline,
                                                  size: 14,
                                                  color: Colors.blue[700],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              // Notes (if any)
                              if (entry.notes.isNotEmpty) 
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.notes,
                                          size: 14,
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            entry.notes,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddEntry,
        backgroundColor: AppConstants.primaryColor,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }
}
