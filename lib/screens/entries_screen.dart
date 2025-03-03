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

class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  DateTime _selectedMonth = DateTime.now();
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshEntries();
    });
  }

  void _refreshEntries() {
    Provider.of<TimeEntryProvider>(context, listen: false).refreshTimeEntries();
  }

  Future<void> _navigateToAddEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimeEntryFormScreen(),
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
        title: const Text('Time Entries'),
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

                // Group entries by client and project
                final groupedByClient = provider.groupEntriesByClient(displayedEntries);
                final clientNames = groupedByClient.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount: clientNames.length,
                  itemBuilder: (context, index) {
                    final clientName = clientNames[index];
                    final clientEntries = groupedByClient[clientName]!;
                    final totalClientHours = provider.calculateTotalHours(clientEntries);
                    final billablePercentage = provider.calculateBillablePercentage(clientEntries);
                    
                    // Group by project within this client
                    final groupedByProject = provider.groupEntriesByProject(clientEntries);
                    final projectNames = groupedByProject.keys.toList()..sort();
                    
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingMd,
                        vertical: AppConstants.spacingSm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 18,
                              color: AppConstants.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                clientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text(
                                '${totalClientHours.toStringAsFixed(1)} hrs',
                                style: TextStyle(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${billablePercentage.toStringAsFixed(0)}% billable',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${projectNames.length} project${projectNames.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        children: projectNames.map((projectName) {
                          final projectEntries = groupedByProject[projectName]!;
                          final totalProjectHours = provider.calculateTotalHours(projectEntries);
                          
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: ExpansionTile(
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.folder,
                                    size: 16,
                                    color: Colors.amber[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      projectName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${totalProjectHours.toStringAsFixed(1)} hrs · ${projectEntries.length} entries',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              children: projectEntries.map((entry) {
                                // Sort entries by date, most recent first
                                projectEntries.sort((a, b) => b.date.compareTo(a.date));
                                
                                return Dismissible(
                                  key: Key('entry-${entry.id}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red[400],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24.0),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    await _confirmDelete(entry);
                                    return false; // We handle deletion in the confirm dialog
                                  },
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(8.0),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? Colors.grey[800]
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.task_alt,
                                        size: 20,
                                        color: isDarkMode
                                            ? Colors.grey[300]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    title: Text(
                                      entry.taskName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          key: ValueKey('entry_details_${entry.id}'),
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 12,
                                              color: isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _dateFormat.format(entry.date),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDarkMode
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                            if (entry.notes.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.notes,
                                                size: 12,
                                                color: isDarkMode
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      key: ValueKey('entry_actions_${entry.id}'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (entry.isBillable)
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withAlpha(25),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Icon(
                                              Icons.attach_money,
                                              size: 14,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppConstants.primaryColor.withAlpha(25),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${entry.hours} hrs',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppConstants.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TimeEntryFormScreen(
                                            entry: entry,
                                          ),
                                        ),
                                      ).then((result) {
                                        if (result == true) {
                                          _refreshEntries();
                                        }
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
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
