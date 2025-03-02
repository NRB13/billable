import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get tasks => _tasks;
  bool get isLoading => _isLoading;

  // Initialize and load tasks
  TaskProvider() {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    _isLoading = true;
    notifyListeners();
    
    _tasks = await _databaseService.getTasks();
    
    _isLoading = false;
    notifyListeners();
  }

  // Refresh tasks from database
  Future<void> refreshTasks() async {
    await _loadTasks();
  }

  // Add a new task
  Future<int> addTask(Map<String, dynamic> task) async {
    final id = await _databaseService.saveTask(task);
    await _loadTasks(); // Reload tasks after adding
    return id;
  }

  // Update an existing task
  Future<void> updateTask(Map<String, dynamic> task) async {
    await _databaseService.saveTask(task);
    await _loadTasks(); // Reload tasks after updating
  }

  // Get tasks for a specific project
  Future<List<Map<String, dynamic>>> getTasksForProject(int projectId) async {
    return await _databaseService.getTasks(projectId: projectId);
  }

  // Get tasks that match a search string
  List<Map<String, dynamic>> searchTasks(String query, {int? projectId}) {
    if (query.isEmpty && projectId == null) {
      return _tasks;
    }
    
    final lowerQuery = query.toLowerCase();
    var filteredTasks = _tasks;
    
    // Filter by project ID if provided
    if (projectId != null) {
      filteredTasks = filteredTasks
        .where((task) => 
          task['project_id'] == projectId)
        .toList();
    }
    
    // Filter by search query if provided
    if (query.isNotEmpty) {
      filteredTasks = filteredTasks
        .where((task) => 
          task['name'].toString().toLowerCase().contains(lowerQuery))
        .toList();
    }
    
    return filteredTasks;
  }

  // Get a task by name and project
  Map<String, dynamic>? getTaskByNameAndProject(String name, int projectId) {
    try {
      return _tasks.firstWhere(
        (task) => 
          task['name'].toString().toLowerCase() == name.toLowerCase() &&
          task['project_id'] == projectId,
      );
    } catch (e) {
      return null;
    }
  }

  // Load all tasks
  Future<void> loadTasks() async {
    final List<Map<String, dynamic>> tasksData = await _databaseService.getTasks();
    _tasks = tasksData;
    notifyListeners();
  }
  
  // Get tasks by project
  List<Map<String, dynamic>> getTasksByProject(int projectId) {
    return _tasks.where((task) => task['project_id'] == projectId).toList();
  }
}
