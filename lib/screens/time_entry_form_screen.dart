import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    // Try to find the client by name
    _selectedClient = clientProvider.getClientByName(_clientNameController.text);
    
    // If client found, try to find the project
    if (_selectedClient != null) {
      final clientProjects = await projectProvider.getProjectsForClient(_selectedClient!['id']);
      if (!mounted) return;
      
      for (final project in clientProjects) {
        if (project['name'] == _projectNameController.text) {
          _selectedProject = project;
          break;
        }
      }
      
      // If project found, try to find the task
      if (_selectedProject != null) {
        final projectTasks = await taskProvider.getTasksForProject(_selectedProject!['id']);
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
    // Get theme brightness to detect if we're in dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Get providers
    final clientProvider = Provider.of<ClientProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Time Entry' : 'New Time Entry'),
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
                  // Client Name Header with Icon
                  Row(
                    children: [
                      Icon(Icons.business, size: 16, color: Theme.of(context).colorScheme.secondary),
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
                        return clientProvider.allClients; // Show all clients if empty
                      }
                      return clientProvider.searchClients(textEditingValue.text);
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
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      // Update the controller to use our saved value
                      if (textEditingController.text.isEmpty && _clientNameController.text.isNotEmpty) {
                        textEditingController.text = _clientNameController.text;
                      }
                      
                      // Update our controller reference when text changes
                      textEditingController.addListener(() {
                        if (_clientNameController.text != textEditingController.text) {
                          _clientNameController.text = textEditingController.text;
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
                            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 600),
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
                      Icon(Icons.work, size: 16, color: Theme.of(context).colorScheme.secondary),
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
                        // Only show projects for the selected client
                        if (_selectedClient != null) {
                          return projectProvider.getProjectsByClient(_selectedClient!['id']);
                        }
                        return projectProvider.projects; // Show all projects if no client selected
                      }
                      
                      // Only show projects for the selected client
                      if (_selectedClient != null) {
                        return projectProvider.searchProjects(
                          textEditingValue.text, 
                          clientId: _selectedClient!['id']
                        );
                      }
                      return projectProvider.searchProjects(textEditingValue.text);
                    },
                    onSelected: (option) {
                      setState(() {
                        _projectNameController.text = option['name'];
                        _selectedProject = option;
                        
                        // If client is not set, set it now
                        if (_selectedClient == null && option['client_id'] != null) {
                          // Find the client by id
                          for (final client in clientProvider.allClients) {
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
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      // Update the controller to use our saved value
                      if (textEditingController.text.isEmpty && _projectNameController.text.isNotEmpty) {
                        textEditingController.text = _projectNameController.text;
                      }
                      
                      // Update our controller reference when text changes
                      textEditingController.addListener(() {
                        if (_projectNameController.text != textEditingController.text) {
                          _projectNameController.text = textEditingController.text;
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
                            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 600),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option['name']),
                                  subtitle: option['client_name'] != null ? Text(option['client_name']) : null,
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
                      Icon(Icons.task, size: 16, color: Theme.of(context).colorScheme.secondary),
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
                        // Only show tasks for the selected project
                        if (_selectedProject != null) {
                          return taskProvider.getTasksByProject(_selectedProject!['id']);
                        }
                        return taskProvider.tasks; // Show all tasks if no project selected
                      }
                      
                      // Only show tasks for the selected project
                      if (_selectedProject != null) {
                        return taskProvider.searchTasks(
                          textEditingValue.text, 
                          projectId: _selectedProject!['id']
                        );
                      }
                      return taskProvider.searchTasks(textEditingValue.text);
                    },
                    onSelected: (option) {
                      setState(() {
                        _taskNameController.text = option['name'];
                        _selectedTask = option;
                        
                        // If project is not set, set it now
                        if (_selectedProject == null && option['project_id'] != null) {
                          // Find the project by id
                          for (final project in projectProvider.projects) {
                            if (project['id'] == option['project_id']) {
                              _selectedProject = project;
                              _projectNameController.text = project['name'];
                              
                              // If client is not set, set it now
                              if (_selectedClient == null && project['client_id'] != null) {
                                // Find the client by id
                                for (final client in clientProvider.allClients) {
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
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      // Update the controller to use our saved value
                      if (textEditingController.text.isEmpty && _taskNameController.text.isNotEmpty) {
                        textEditingController.text = _taskNameController.text;
                      }
                      
                      // Update our controller reference when text changes
                      textEditingController.addListener(() {
                        if (_taskNameController.text != textEditingController.text) {
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
                            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 600),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option['name']),
                                  subtitle: option['project_name'] != null 
                                      ? Text('${option['project_name']}${option['client_name'] != null ? ' - ${option['client_name']}' : ''}') 
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
                      Icon(Icons.event, size: 16, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Date',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Date
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
                        initialValue: DateFormat('yyyy-MM-dd').format(_selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  
                  // Hours Header with Icon
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.secondary),
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
                      'Enter hours worked (e.g., 1.5)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      Icon(Icons.note, size: 16, color: Theme.of(context).colorScheme.secondary),
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
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: AppConstants.primaryButtonStyle,
                      child: _isSubmitting
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : Text(
                              _isEditing ? 'Update Entry' : 'Save Entry',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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

  void _submitForm() async {
    final formState = _formKey.currentState;
    
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Store context-dependent services in variables before async operations
    final timeEntryProvider = Provider.of<TimeEntryProvider>(context, listen: false);
    final clientProvider = Provider.of<ClientProvider>(context, listen: false);
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    try {
      // Create or update entry in database
      final timeEntry = TimeEntry(
        id: _isEditing ? widget.entry!.id : null,
        clientName: _clientNameController.text,
        projectName: _projectNameController.text,
        taskName: _taskNameController.text,
        notes: _notesController.text,
        date: _selectedDate,
        hours: double.parse(_hoursController.text),
        isBillable: _isBillable,
        isSubmitted: _isEditing ? widget.entry!.isSubmitted : false,
      );

      // If client doesn't exist, create it
      if (_selectedClient == null && _clientNameController.text.isNotEmpty) {
        final clientId = await clientProvider.addClient({
          'name': _clientNameController.text,
          'contact_name': '',
          'email': '',
          'phone': '',
          'address': '',
          'notes': '',
        });
        
        if (!mounted) return;
        
        // If project doesn't exist, create it
        if (_selectedProject == null && _projectNameController.text.isNotEmpty) {
          final projectId = await projectProvider.addProject({
            'client_id': clientId,
            'name': _projectNameController.text,
            'description': '',
            'hourly_rate': 0.0,
            'is_billable': _isBillable ? 1 : 0,
            'is_active': 1,
          });
          
          if (!mounted) return;
          
          // If task doesn't exist, create it
          if (_selectedTask == null && _taskNameController.text.isNotEmpty) {
            await taskProvider.addTask({
              'project_id': projectId,
              'name': _taskNameController.text,
              'description': '',
            });
            
            if (!mounted) return;
          }
        }
      }

      if (_isEditing) {
        await timeEntryProvider.updateTimeEntry(timeEntry);
      } else {
        await timeEntryProvider.addTimeEntry(timeEntry);
      }

      if (!mounted) return;
      
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Time entry updated!' : 'Time entry added!'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
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
