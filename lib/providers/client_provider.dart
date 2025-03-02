import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class ClientProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _allClients = [];
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get clients => _clients;
  List<Map<String, dynamic>> get allClients => _allClients;
  bool get isLoading => _isLoading;

  // Initialize and load clients
  ClientProvider() {
    _loadClients();
  }

  Future<void> _loadClients() async {
    _isLoading = true;
    notifyListeners();
    
    _clients = await _databaseService.getClients();
    _allClients = _clients;
    
    _isLoading = false;
    notifyListeners();
  }

  // Refresh clients from database
  Future<void> refreshClients() async {
    await _loadClients();
  }

  // Add a new client
  Future<int> addClient(Map<String, dynamic> client) async {
    final id = await _databaseService.saveClient(client);
    await _loadClients(); // Reload clients after adding
    return id;
  }

  // Update an existing client
  Future<void> updateClient(Map<String, dynamic> client) async {
    await _databaseService.saveClient(client);
    await _loadClients(); // Reload clients after updating
  }

  // Get clients that match a search string
  List<Map<String, dynamic>> searchClients(String query) {
    if (query.isEmpty) {
      return _clients;
    }
    
    final lowerQuery = query.toLowerCase();
    return _clients
      .where((client) => 
        client['name'].toString().toLowerCase().contains(lowerQuery))
      .toList();
  }

  // Get a client by name
  Map<String, dynamic>? getClientByName(String name) {
    try {
      return _clients.firstWhere(
        (client) => client['name'].toString().toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
