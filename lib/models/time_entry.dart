import 'package:intl/intl.dart';

class TimeEntry {
  final int? id;
  final String clientName;
  final String projectName;
  final String taskName;
  final String notes;
  final DateTime date;
  final double hours;
  final bool isBillable;
  final bool isSubmitted;

  TimeEntry({
    this.id,
    required this.clientName,
    required this.projectName,
    required this.taskName,
    required this.notes,
    required this.date,
    required this.hours,
    required this.isBillable,
    this.isSubmitted = false,
  });

  // Convert TimeEntry to a Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_name': clientName,
      'project_name': projectName,
      'task_name': taskName,
      'notes': notes,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'hours': hours,
      'is_billable': isBillable ? 1 : 0,
      'is_submitted': isSubmitted ? 1 : 0,
    };
  }

  // Create a TimeEntry object from a Map (from SQLite)
  factory TimeEntry.fromMap(Map<String, dynamic> map) {
    return TimeEntry(
      id: map['id'],
      clientName: map['client_name'],
      projectName: map['project_name'],
      taskName: map['task_name'],
      notes: map['notes'],
      date: DateFormat('yyyy-MM-dd').parse(map['date']),
      hours: map['hours'],
      isBillable: map['is_billable'] == 1,
      isSubmitted: map['is_submitted'] == 1,
    );
  }

  // Convert TimeEntry to a CSV row format for Jaris
  List<String> toJarisCsvRow() {
    String formattedDate = DateFormat('M/d/yyyy').format(date);
    
    return [
      formattedDate,  // Date
      clientName,     // Client
      projectName,    // Project
      taskName,       // Task
      hours.toString(), // Hours
      notes,          // Notes
      isBillable ? 'Yes' : 'No', // Billable
      '',             // Invoice Number
      '',             // Rate
      '',             // Amount
    ];
  }

  // Create a copy of this TimeEntry with optional updated values
  TimeEntry copyWith({
    int? id,
    String? clientName,
    String? projectName,
    String? taskName,
    String? notes,
    DateTime? date,
    double? hours,
    bool? isBillable,
    bool? isSubmitted,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      projectName: projectName ?? this.projectName,
      taskName: taskName ?? this.taskName,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      hours: hours ?? this.hours,
      isBillable: isBillable ?? this.isBillable,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }
}
