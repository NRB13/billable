import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class ProjectProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get projects => _projects;
  bool get isLoading => _isLoading;

  // Initialize and load projects
  ProjectProvider() {
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    _isLoading = true;
    notifyListeners();
    
    _projects = await _databaseService.getProjects();
    
    _isLoading = false;
    notifyListeners();
  }

  // Refresh projects from database
  Future<void> refreshProjects() async {
    await _loadProjects();
  }

  // Add a new project
  Future<int> addProject(Map<String, dynamic> project) async {
    final id = await _databaseService.saveProject(project);
    await _loadProjects(); // Reload projects after adding
    return id;
  }

  // Update an existing project
  Future<void> updateProject(Map<String, dynamic> project) async {
    await _databaseService.saveProject(project);
    await _loadProjects(); // Reload projects after updating
  }

  // Get projects for a specific client
  Future<List<Map<String, dynamic>>> getProjectsForClient(int clientId) async {
    return await _databaseService.getProjects(clientId: clientId);
  }

  // Get projects that match a search string
  List<Map<String, dynamic>> searchProjects(String query, {int? clientId}) {
    if (query.isEmpty && clientId == null) {
      return _projects;
    }
    
    final lowerQuery = query.toLowerCase();
    var filteredProjects = _projects;
    
    // Filter by client ID if provided
    if (clientId != null) {
      filteredProjects = filteredProjects
        .where((project) => 
          project['client_id'] == clientId)
        .toList();
    }
    
    // Filter by search query if provided
    if (query.isNotEmpty) {
      filteredProjects = filteredProjects
        .where((project) => 
          project['name'].toString().toLowerCase().contains(lowerQuery))
        .toList();
    }
    
    return filteredProjects;
  }

  // Get a project by name and client
  Map<String, dynamic>? getProjectByNameAndClient(String name, int clientId) {
    try {
      return _projects.firstWhere(
        (project) => 
          project['name'].toString().toLowerCase() == name.toLowerCase() &&
          project['client_id'] == clientId,
      );
    } catch (e) {
      return null;
    }
  }

  // Load all projects
  Future<void> loadProjects() async {
    final List<Map<String, dynamic>> projectsData = await _databaseService.getProjects();
    _projects = projectsData;
    notifyListeners();
  }
  
  // Get projects by client
  List<Map<String, dynamic>> getProjectsByClient(int clientId) {
    return _projects.where((project) => project['client_id'] == clientId).toList();
  }
}
