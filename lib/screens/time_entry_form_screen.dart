import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/time_entry.dart';
import '../providers/time_entry_provider.dart';
import '../providers/client_provider.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';

class TimeEntryFormScreen extends StatefulWidget {
  final TimeEntry? entry;

  const TimeEntryFormScreen({super.key, this.entry});

  @override
  State<TimeEntryFormScreen> createState() => _TimeEntryFormScreenState();
}

class _TimeEntryFormScreenState extends State<TimeEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isLoading = true;
  late bool _isEditing;
  bool _isBulkEntry = false; // Flag to track if we're in bulk entry mode

  // Date range for bulk entry
  DateTime? _startDate;
  DateTime? _endDate;
  bool _weekdaysOnly = true;

  // List to store bulk entries
  List<Map<String, dynamic>> _bulkEntries = [];

  // Form controllers
  late TextEditingController _clientNameController;
  late TextEditingController _projectNameController;
  late TextEditingController _taskNameController;
  late TextEditingController _notesController;
  late TextEditingController _hoursController;

  // Selected entities
  Map<String, dynamic>? _selectedClient;
  Map<String, dynamic>? _selectedProject;
  Map<String, dynamic>? _selectedTask;

  // Other form values
  DateTime _selectedDate = DateTime.now();
  bool _isBillable = true;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _clientNameController = TextEditingController();
    _projectNameController = TextEditingController();
    _taskNameController = TextEditingController();
    _notesController = TextEditingController();
    _hoursController = TextEditingController();

    _isEditing = widget.entry != null;

    // Load entry data if editing
    if (_isEditing) {
      _loadExistingEntry();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadExistingEntry() {
    _clientNameController.text = widget.entry!.clientName;
    _projectNameController.text = widget.entry!.projectName;
    _taskNameController.text = widget.entry!.taskName;
    _notesController.text = widget.entry!.notes;
    _hoursController.text = widget.entry!.hours.toString();
    _selectedDate = widget.entry!.date;
    _isBillable = widget.entry!.isBillable;

    // Load related entities after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingEntities();
    });

    setState(() {
      _isLoading = false;
    });
  }

  // Load client, project, and task data for existing entry
  Future<void> _loadExistingEntities() async {
    if (!mounted) return;

    final clientProvider = Provider.of<ClientProvider>(context, listen: false);
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    // Try to find the client by name
    _selectedClient = clientProvider.clients
        .firstWhere((client) => client['name'] == _clientNameController.text);

    // If client found, try to find the project
    if (_selectedClient != null) {
      final clientProjects =
          projectProvider.getProjectsByClient(_selectedClient!['id']);
      if (!mounted) return;

      for (final project in clientProjects) {
        if (project['name'] == _projectNameController.text) {
          _selectedProject = project;
          break;
        }
      }

      // If project found, try to find the task
      if (_selectedProject != null) {
        final projectTasks =
            taskProvider.getTasksByProject(_selectedProject!['id']);
        if (!mounted) return;

        for (final task in projectTasks) {
          if (task['name'] == _taskNameController.text) {
            _selectedTask = task;
            break;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final clientProvider = Provider.of<ClientProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final timeEntryProvider = Provider.of<TimeEntryProvider>(context);

    // Create a title that uses the timeEntryProvider data
    final appBarTitle = widget.entry == null
        ? 'New Time Entry${timeEntryProvider.timeEntries.isNotEmpty ? " (${timeEntryProvider.timeEntries.length} entries)" : ""}'
        : 'Edit Time Entry';

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Entry Mode Toggle
                  if (!_isEditing) // Only show toggle for new entries
                    _buildBulkEntryToggle(),

                  // Client Name Header with Icon
                  Row(
                    children: [
                      Icon(Icons.business,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Client Name',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Client Name with Autocomplete
                  Autocomplete<Map<String, dynamic>>(
                    displayStringForOption: (option) => option['name'],
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Map<String, dynamic>>.empty(); // Return empty list when no input
                      }
                      return clientProvider.clients
                          .where((client) =>
                              client['name'].toLowerCase().contains(textEditingValue.text.toLowerCase()))
                          .toList();
                    },
                    onSelected: (option) {
                      setState(() {
                        _clientNameController.text = option['name'];
                        _selectedClient = option;

                        // Clear project and task when client changes
                        if (_selectedProject != null &&
                            _selectedProject!['client_id'] != option['id']) {
                          _projectNameController.clear();
                          _taskNameController.clear();
                          _selectedProject = null;
                          _selectedTask = null;
                        }
                      });
                    },
                    fieldViewBuilder: (context, textEditingController,
                        focusNode, onFieldSubmitted) {
                      // Update the controller to use our saved value
                      if (textEditingController.text.isEmpty &&
                          _clientNameController.text.isNotEmpty) {
                        textEditingController.text = _clientNameController.text;
                      }

                      // Update our controller reference when text changes
                      textEditingController.addListener(() {
                        if (_clientNameController.text !=
                            textEditingController.text) {
                          _clientNameController.text =
                              textEditingController.text;
                        }
                      });

                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: AppConstants.inputDecoration(
                          '',
                          'Start typing to see matching clients',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Client name is required';
                          }
                          return null;
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxHeight: 200, maxWidth: 600),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option['name']),
                                  onTap: () {
                                    onSelected(option);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingMd),

                  // Project Name Header with Icon
                  Row(
                    children: [
                      Icon(Icons.work,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Project Name',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Project Name with Autocomplete
                  Autocomplete<Map<String, dynamic>>(
                    displayStringForOption: (option) => option['name'],
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Map<String, dynamic>>.empty(); // Return empty list when no input
                      }
                      return projectProvider.projects
                          .where((project) => 
                              (_selectedClient == null || 
                               project['client_id'] == _selectedClient!['id']) &&
                              project['name'].toLowerCase().contains(textEditingValue.text.toLowerCase()))
                          .toList();
                    },
                    onSelected: (option) {
                      setState(() {
                        _projectNameController.text = option['name'];
                        _selectedProject = option;

                        // If client is not set, set it now
                        if (_selectedClient == null &&
                            option['client_id'] != null) {
                          // Find the client by id
                          for (final client in clientProvider.clients) {
                            if (client['id'] == option['client_id']) {
                              _selectedClient = client;
                              _clientNameController.text = client['name'];
                              break;
                            }
                          }
                        }

                        // Clear task when project changes
                        if (_selectedTask != null &&
                            _selectedTask!['project_id'] != option['id']) {
                          _taskNameController.clear();
                          _selectedTask = null;
                        }
                      });
                    },
                    fieldViewBuilder: (context, textEditingController,
                        focusNode, onFieldSubmitted) {
                      // Update the controller to use our saved value
                      if (textEditingController.text.isEmpty &&
                          _projectNameController.text.isNotEmpty) {
                        textEditingController.text =
                            _projectNameController.text;
                      }

                      // Update our controller reference when text changes
                      textEditingController.addListener(() {
                        if (_projectNameController.text !=
                            textEditingController.text) {
                          _projectNameController.text =
                              textEditingController.text;
                        }
                      });

                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: AppConstants.inputDecoration(
                          '',
                          'Start typing to see matching projects',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Project name is required';
                          }
                          return null;
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxHeight: 200, maxWidth: 600),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option['name']),
                                  subtitle: option['client_name'] != null
                                      ? Text(option['client_name'])
                                      : null,
                                  onTap: () {
                                    onSelected(option);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingMd),

                  // Task Name Header with Icon
                  Row(
                    children: [
                      Icon(Icons.task,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Task Name',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Task Name with Autocomplete
                  Autocomplete<Map<String, dynamic>>(
                    displayStringForOption: (option) => option['name'],
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Map<String, dynamic>>.empty(); // Return empty list when no input
                      }
                      return taskProvider.tasks
                          .where((task) =>
                              (_selectedProject == null || 
                               task['project_id'] == _selectedProject!['id']) &&
                              task['name'].toLowerCase().contains(textEditingValue.text.toLowerCase()))
                          .toList();
                    },
                    onSelected: (option) {
                      setState(() {
                        _taskNameController.text = option['name'];
                        _selectedTask = option;

                        // If project is not set, set it now
                        if (_selectedProject == null &&
                            option['project_id'] != null) {
                          // Find the project by id
                          for (final project in projectProvider.projects) {
                            if (project['id'] == option['project_id']) {
                              _selectedProject = project;
                              _projectNameController.text = project['name'];

                              // If client is not set, set it now
                              if (_selectedClient == null &&
                                  project['client_id'] != null) {
                                // Find the client by id
                                for (final client
                                    in clientProvider.clients) {
                                  if (client['id'] == project['client_id']) {
                                    _selectedClient = client;
                                    _clientNameController.text = client['name'];
                                    break;
                                  }
                                }
                              }
                              break;
                            }
                          }
                        }
                      });
                    },
                    fieldViewBuilder: (context, textEditingController,
                        focusNode, onFieldSubmitted) {
                      // Update the controller to use our saved value
                      if (textEditingController.text.isEmpty &&
                          _taskNameController.text.isNotEmpty) {
                        textEditingController.text = _taskNameController.text;
                      }

                      // Update our controller reference when text changes
                      textEditingController.addListener(() {
                        if (_taskNameController.text !=
                            textEditingController.text) {
                          _taskNameController.text = textEditingController.text;
                        }
                      });

                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: AppConstants.inputDecoration(
                          '',
                          'Start typing to see matching tasks',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Task name is required';
                          }
                          return null;
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxHeight: 200, maxWidth: 600),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option['name']),
                                  subtitle: option['project_name'] != null
                                      ? Text(
                                          '${option['project_name']}${option['client_name'] != null ? ' - ${option['client_name']}' : ''}')
                                      : null,
                                  onTap: () {
                                    onSelected(option);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingMd),

                  // Date Header with Icon
                  Row(
                    children: [
                      Icon(Icons.event,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Date',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Date input - show different UI based on mode
                  if (!_isBulkEntry)
                    // Single entry date selector
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: AppConstants.inputDecoration(
                            '',
                            'Select date',
                          ).copyWith(
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          initialValue:
                              DateFormat('yyyy-MM-dd').format(_selectedDate),
                        ),
                      ),
                    )
                  else
                    // Bulk entry date range selector
                    _buildBulkEntry(),

                  const SizedBox(height: AppConstants.spacingMd),

                  // Hours Header with Icon
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Hours',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Hours
                  TextFormField(
                    controller: _hoursController,
                    decoration: AppConstants.inputDecoration(
                      '',
                      !_isBulkEntry
                          ? 'Enter hours worked (e.g., 1.5)'
                          : 'Enter default hours per day',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Hours are required';
                      }
                      final double? hours = double.tryParse(value);
                      if (hours == null || hours <= 0) {
                        return 'Please enter a valid number of hours';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingMd),

                  // Notes Header with Icon
                  Row(
                    children: [
                      Icon(Icons.note,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Notes',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Notes - Restored to previous style with multi-line
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: AppConstants.inputDecoration(
                      '',
                      'Enter any additional notes',
                    ).copyWith(
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),

                  // Is Billable
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Colors.grey.withAlpha(128),
                        width: 1,
                      ),
                    ),
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: SwitchListTile(
                        title: Row(
                          children: [
                            const Icon(Icons.attach_money),
                            const SizedBox(width: 8),
                            Text(
                              'Billable',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        value: _isBillable,
                        activeColor: AppConstants.primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _isBillable = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  // Submit Button
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  _isBulkEntry
                                      ? "Submit Bulk Entries"
                                      : (_isEditing
                                          ? "Update Time Entry"
                                          : "Create Time Entry"),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
        ),
      ),
    );
  }

  Widget _buildBulkEntryToggle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          const Text('Single Entry'),
          Expanded(
            child: Center(
              child: Switch(
                value: _isBulkEntry,
                onChanged: (value) {
                  setState(() {
                    _isBulkEntry = value;
                    // Clear any existing bulk entries when toggling
                    if (!_isBulkEntry) {
                      _bulkEntries = [];
                    }
                  });
                },
                activeColor: AppConstants.primaryColor,
                thumbColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.disabled)) {
                      return Colors.grey.shade400;
                    }
                    return Colors.white;
                  },
                ),
              ),
            ),
          ),
          const Text('Bulk Entry'),
        ],
      ),
    );
  }

  Widget _buildBulkEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.date_range,
                        color: AppConstants.primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Text('Weekdays only',
                            style: TextStyle(fontSize: 14)),
                        Switch(
                          value: _weekdaysOnly,
                          activeColor: AppConstants.primaryColor,
                          onChanged: (value) {
                            setState(() {
                              _weekdaysOnly = value;
                              if (_startDate != null && _endDate != null) {
                                // Refresh preview if we already have date range
                                _createBulkEntries();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectStartDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color:
                                    Colors.grey.withAlpha(76)), // ~0.3 opacity
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                _startDate != null
                                    ? DateFormat('MMM d, yyyy')
                                        .format(_startDate!)
                                    : 'Start Date',
                                style: TextStyle(
                                  color: _startDate != null
                                      ? Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child:
                          const Icon(Icons.arrow_forward, color: Colors.grey),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: _selectEndDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color:
                                    Colors.grey.withAlpha(76)), // ~0.3 opacity
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                _endDate != null
                                    ? DateFormat('MMM d, yyyy')
                                        .format(_endDate!)
                                    : 'End Date',
                                style: TextStyle(
                                  color: _endDate != null
                                      ? Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _startDate != null && _endDate != null 
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Range: ${_endDate!.difference(_startDate!).inDays + 1} days',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (_weekdaysOnly)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Excluding weekends (${_calculateWeekdays(_startDate!, _endDate!)} weekdays)',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : const Text(
                            'Select both dates to continue',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.preview),
                      label: const Text('Generate Preview'),
                      onPressed: _startDate != null && _endDate != null 
                        ? _createBulkEntries 
                        : null, // Disable button when dates not selected
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Preview of bulk entries
        _buildBulkEntriesPreview(),
      ],
    );
  }

  int _calculateWeekdays(DateTime start, DateTime end) {
    int count = 0;
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (current.weekday < 6) {
        // Monday to Friday
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  Future<bool> _submitBulkEntries() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      int successCount = 0;
      int failCount = 0;
      final timeEntryProvider =
          Provider.of<TimeEntryProvider>(context, listen: false);

      // Get client, project, and task IDs once outside the loop for efficiency
      final clientId = await _getOrCreateClient();
      final projectId = await _getOrCreateProject(clientId);
      final taskId = await _getOrCreateTask(projectId);

      for (var entry in _bulkEntries) {
        try {
          final timeEntry = TimeEntry(
            id: null, // New entry
            date: entry['date'] as DateTime,
            clientName: _clientNameController.text,
            projectName: _projectNameController.text,
            taskName: _taskNameController.text,
            notes: entry['notes'] as String,
            hours: entry['hours'] as double,
            isBillable: entry['isBillable'] as bool,
            isSubmitted: false,
            clientId: clientId, // Use clientId
            projectId: projectId, // Use projectId
            taskId: taskId, // Use taskId
          );

          await timeEntryProvider.addTimeEntry(timeEntry);
          successCount++;
        } catch (e) {
          debugPrint('Error adding bulk entry: $e');
          failCount++;
        }
      }

      // Use a check-then-act pattern within a synchronous block after async operations
      if (!mounted) return false;

      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Created $successCount time entries${failCount > 0 ? ' ($failCount failed)' : ''}'),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create any time entries'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error in bulk submission: $e');

      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _createBulkEntries() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start and end date'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    if (_clientNameController.text.isEmpty ||
        _projectNameController.text.isEmpty ||
        _taskNameController.text.isEmpty ||
        _hoursController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    // Clear any existing entries
    setState(() {
      _bulkEntries.clear();
    });

    // Calculate the number of days between start and end dates
    final days = _endDate!.difference(_startDate!).inDays + 1;

    // Add an entry for each day in the range
    for (var i = 0; i < days; i++) {
      final date = _startDate!.add(Duration(days: i));

      // Skip weekends if weekdaysOnly is selected
      if (_weekdaysOnly &&
          (date.weekday == DateTime.saturday ||
              date.weekday == DateTime.sunday)) {
        continue;
      }

      _bulkEntries.add({
        'date': date,
        'clientName': _clientNameController.text,
        'projectName': _projectNameController.text,
        'taskName': _taskNameController.text,
        'notes': _notesController.text,
        'hours': double.tryParse(_hoursController.text) ?? 0.0,
        'isBillable': _isBillable,
      });
    }

    // Sort entries by date
    _bulkEntries.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    if (_bulkEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No entries created. Please check your date range and weekday filter.'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_bulkEntries.length} entries created. Review below and submit when ready.'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    }
  }

  Widget _buildBulkEntriesPreview() {
    if (_bulkEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.info_outline, size: 40, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'Set date range and click "Generate Preview" above to create entries',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bulk Entries Preview',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${_bulkEntries.length} Entries',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 300, // Limit height to prevent screen overflow
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _bulkEntries.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = _bulkEntries[index];
                return Dismissible(
                  key: Key('entry-$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red.withAlpha(200),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    setState(() {
                      _bulkEntries.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Entry removed'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('EEE, MMM d, yyyy')
                                .format(entry['date']),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withAlpha(40),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${entry['hours']} hrs',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${entry['clientName']} · ${entry['projectName']} · ${entry['taskName']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editBulkEntry(index),
                      tooltip: 'Edit Entry',
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regenerate'),
                  onPressed: () {
                    setState(() {
                      _bulkEntries.clear();
                    });
                    _createBulkEntries();
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Date'),
                  onPressed: _addCustomBulkEntry,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editBulkEntry(int index) {
    final entry = _bulkEntries[index];

    // Create temporary controllers for editing
    final hoursController =
        TextEditingController(text: entry['hours'].toString());
    final notesController = TextEditingController(text: entry['notes']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Edit Entry - ${DateFormat('EEE, MMM d').format(entry['date'])}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hoursController,
                decoration: const InputDecoration(
                  labelText: 'Hours',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: entry['isBillable'],
                    onChanged: (value) {
                      setState(() {
                        entry['isBillable'] = value ?? true;
                      });
                      Navigator.of(context).pop();
                      _editBulkEntry(
                          index); // Reopen dialog with updated values
                    },
                  ),
                  const Text('Billable'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final hours = double.tryParse(hoursController.text);
              if (hours != null && hours > 0) {
                setState(() {
                  _bulkEntries[index]['hours'] = hours;
                  _bulkEntries[index]['notes'] = notesController.text;
                });
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid hours'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addCustomBulkEntry() {
    final dateController = TextEditingController();
    final hoursController = TextEditingController(text: _hoursController.text);
    final notesController = TextEditingController(text: _notesController.text);
    DateTime selectedDate = DateTime.now();
    bool isBillable = _isBillable;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Add Custom Entry'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date picker
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          selectedDate = picked;
                          dateController.text =
                              DateFormat('yyyy-MM-dd').format(selectedDate);
                        });
                      }
                    },
                    child: IgnorePointer(
                      child: TextField(
                        controller: dateController
                          ..text =
                              DateFormat('yyyy-MM-dd').format(selectedDate),
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: hoursController,
                    decoration: const InputDecoration(
                      labelText: 'Hours',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: isBillable,
                        onChanged: (value) {
                          setStateDialog(() {
                            isBillable = value ?? true;
                          });
                        },
                      ),
                      const Text('Billable'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final hours = double.tryParse(hoursController.text);
                  if (hours != null && hours > 0) {
                    setState(() {
                      _bulkEntries.add({
                        'date': selectedDate,
                        'clientName': _clientNameController.text,
                        'projectName': _projectNameController.text,
                        'taskName': _taskNameController.text,
                        'notes': notesController.text,
                        'hours': hours,
                        'isBillable': isBillable,
                      });
                    });
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter valid hours'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<int> _getOrCreateClient() async {
    // Check if client with this name already exists
    final clientProvider = Provider.of<ClientProvider>(context, listen: false);
    final existingClients = clientProvider.clients
        .where((client) => client['name'] == _clientNameController.text)
        .toList();

    if (existingClients.isNotEmpty) {
      return existingClients.first['id'];
    }

    // Create a new client
    final clientId = await clientProvider.addClient({
      'name': _clientNameController.text,
      'contact_name': '',
      'email': '',
      'phone': '',
      'address': '',
      'notes': '',
    });

    return clientId;
  }

  Future<int> _getOrCreateProject(int clientId) async {
    // Check if project with this name already exists for this client
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final projectsForClient = projectProvider.getProjectsByClient(clientId);
    final existingProjects = projectsForClient
        .where((project) => project['name'] == _projectNameController.text)
        .toList();

    if (existingProjects.isNotEmpty) {
      return existingProjects.first['id'];
    }

    // Create a new project
    final projectId = await projectProvider.addProject({
      'client_id': clientId,
      'name': _projectNameController.text,
      'description': '',
      'hourly_rate': 0.0,
      'is_billable': _isBillable ? 1 : 0,
      'is_active': 1,
    });

    return projectId;
  }

  Future<int> _getOrCreateTask(int projectId) async {
    // Check if task with this name already exists for this project
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final tasksForProject = taskProvider.getTasksByProject(projectId);
    final existingTasks = tasksForProject
        .where((task) => task['name'] == _taskNameController.text)
        .toList();

    if (existingTasks.isNotEmpty) {
      return existingTasks.first['id'];
    }

    // Create a new task
    final taskId = await taskProvider.addTask({
      'project_id': projectId,
      'name': _taskNameController.text,
      'description': '',
    });

    return taskId;
  }

  Future<bool> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isBulkEntry) {
        // Handle bulk entry submission
        return await _submitBulkEntries();
      } else {
        // Handle single entry submission
        final clientId = await _getOrCreateClient();
        final projectId = await _getOrCreateProject(clientId);
        final taskId = await _getOrCreateTask(projectId);

        // Create time entry
        final date = _selectedDate;

        final timeEntry = TimeEntry(
          id: widget.entry?.id,
          date: date,
          clientName: _clientNameController.text,
          projectName: _projectNameController.text,
          taskName: _taskNameController.text,
          notes: _notesController.text,
          hours: double.parse(_hoursController.text),
          isBillable: _isBillable,
          isSubmitted: false,
          clientId: clientId,
          projectId: projectId,
          taskId: taskId,
        );

        // Get provider before async operations
        final timeEntryProvider =
            // ignore: use_build_context_synchronously
            Provider.of<TimeEntryProvider>(context, listen: false);

        if (widget.entry == null) {
          // New entry
          await timeEntryProvider.addTimeEntry(timeEntry);
        } else {
          // Update existing entry
          await timeEntryProvider.updateTimeEntry(timeEntry);
        }

        // Check if widget is still mounted before using context
        if (!mounted) return false;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.entry == null
                ? 'Time entry created successfully'
                : 'Time entry updated successfully'),
          ),
        );

        // Return to previous screen
        Navigator.pop(context, true);
        return true;
      }
    } catch (e) {
      debugPrint('Error submitting form: $e');

      // Check if widget is still mounted before using context
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _projectNameController.dispose();
    _taskNameController.dispose();
    _notesController.dispose();
    _hoursController.dispose();
    super.dispose();
  }
}
