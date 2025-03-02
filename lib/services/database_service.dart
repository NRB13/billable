// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/time_entry.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static const String _databaseName = 'billable.db';
  
  // Database version - increase this number when schema changes
  static const int _databaseVersion = 2;
  
  // Singleton constructor
  factory DatabaseService() {
    return _instance;
  }
  
  // Internal constructor
  DatabaseService._internal();
  
  // Database instance
  static Database? _database;
  
  // Get database instance
  Future<Database> get database async {
    // If database exists, return it
    if (_database != null) return _database!;
    
    // If not, initialize database
    _database = await _initDatabase();
    return _database!;
  }
  
  // Initialize database
  Future<Database> _initDatabase() async {
    if (kDebugMode) {
      debugPrint('Initializing database');
    }
    
    // Get database path
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    if (kDebugMode) {
      debugPrint('Database path: $path');
    }
    
    // Open database
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }
  
  // Upgrade database - this runs when version number increases
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) debugPrint('Upgrading database from version $oldVersion to $newVersion');
    
    // Upgrade from version 1 to 2 (adding client, project, task and settings tables)
    if (oldVersion < 2) {
      await _upgradeToV2(db);
    }
    
    // For future versions, add more conditions:
    // if (oldVersion < 3) {
    //   await _upgradeToV3(db);
    // }
    
    // if (oldVersion < 4) {
    //   await _upgradeToV4(db);
    // }
  }
  
  // Upgrade from version 1 to version 2
  Future<void> _upgradeToV2(Database db) async {
    try {
      if (kDebugMode) debugPrint('Creating settings table...');
      // Create settings table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings(
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      
      // Insert default settings
      try {
        await db.insert('settings', {'key': 'dark_mode', 'value': '0'});
        await db.insert('settings', {'key': 'default_currency', 'value': 'USD'});
        await db.insert('settings', {'key': 'default_hours_per_day', 'value': '8'});
        await db.insert('settings', {'key': 'auto_backup', 'value': '0'});
        if (kDebugMode) debugPrint('Default settings added successfully');
      } catch (e) {
        if (kDebugMode) debugPrint('Error inserting default settings: $e');
      }
      
      // Create clients table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS clients(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          contact_name TEXT,
          email TEXT,
          phone TEXT,
          address TEXT,
          notes TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      
      // Create projects table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS projects(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          client_id INTEGER,
          name TEXT NOT NULL,
          description TEXT,
          hourly_rate REAL,
          is_billable INTEGER NOT NULL DEFAULT 1,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
          UNIQUE(client_id, name)
        )
      ''');
      
      // Create tasks table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          project_id INTEGER,
          name TEXT NOT NULL,
          description TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
          UNIQUE(project_id, name)
        )
      ''');
      
      // Migrate existing data from v1 format to v2 format if time_entries table exists
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='time_entries'"
      );
      
      if (tableExists.isNotEmpty) {
        // Get all unique clients from time_entries
        final clients = await db.rawQuery('''
          SELECT DISTINCT client_name FROM time_entries
        ''');
        
        // Insert clients and collect mapping
        Map<String, int> clientMapping = {};
        for (var client in clients) {
          final clientName = client['client_name'] as String;
          final id = await db.insert('clients', {
            'name': clientName,
            'created_at': DateTime.now().toIso8601String()
          });
          clientMapping[clientName] = id;
        }
        
        // Get all unique projects and create mapping
        Map<String, int> projectMapping = {};
        final projects = await db.rawQuery('''
          SELECT DISTINCT client_name, project_name FROM time_entries
        ''');
        
        for (var project in projects) {
          final clientName = project['client_name'] as String;
          final projectName = project['project_name'] as String;
          final clientId = clientMapping[clientName];
          
          if (clientId != null) {
            final id = await db.insert('projects', {
              'client_id': clientId,
              'name': projectName,
              'is_billable': 1,
              'is_active': 1,
              'created_at': DateTime.now().toIso8601String()
            });
            // Create a composite key for mapping
            projectMapping['$clientName:$projectName'] = id;
          }
        }
        
        // Get all unique tasks and create them
        final tasks = await db.rawQuery('''
          SELECT DISTINCT client_name, project_name, task_name FROM time_entries
        ''');
        
        for (var task in tasks) {
          final clientName = task['client_name'] as String;
          final projectName = task['project_name'] as String;
          final taskName = task['task_name'] as String;
          
          final projectId = projectMapping['$clientName:$projectName'];
          
          if (projectId != null) {
            await db.insert('tasks', {
              'project_id': projectId,
              'name': taskName,
              'created_at': DateTime.now().toIso8601String()
            });
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error upgrading database to V2: $e');
      // Even if we have errors, we continue to ensure partial functionality
    }
  }
  
  // Example template for future migrations
  // Future<void> _upgradeToV3(Database db) async {
  //   try {
  //     // Add new tables or columns for V3
  //     await db.execute('''
  //       ALTER TABLE settings ADD COLUMN new_feature INTEGER DEFAULT 0
  //     ''');
  //     
  //     // Other migration steps...
  //   } catch (e) {
  //     if (kDebugMode) debugPrint('Error upgrading database to V3: $e');
  //   }
  // }
  
  // Create database
  Future<void> _createDatabase(Database db, int version) async {
    if (kDebugMode) {
      debugPrint('Creating new database at version $version');
    }
    
    // Create time entries table
    await db.execute('''
      CREATE TABLE time_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_name TEXT NOT NULL,
        project_name TEXT NOT NULL,
        task_name TEXT NOT NULL,
        notes TEXT,
        date TEXT NOT NULL,
        hours REAL NOT NULL,
        is_billable INTEGER NOT NULL DEFAULT 1,
        is_submitted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    // If we're creating the database at version 2 or higher, 
    // we need to create the additional tables
    if (version >= 2) {
      await _upgradeToV2(db);
    }
  }
  
  // Insert a time entry
  Future<int> insertTimeEntry(TimeEntry entry) async {
    final db = await database;
    return await db.insert('time_entries', entry.toMap());
  }

  // Update a time entry
  Future<int> updateTimeEntry(TimeEntry entry) async {
    final db = await database;
    return await db.update(
      'time_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // Delete a time entry
  Future<int> deleteTimeEntry(int id) async {
    final db = await database;
    return await db.delete(
      'time_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mark entries as submitted
  Future<int> markEntriesAsSubmitted(List<int> ids) async {
    final db = await database;
    return await db.update(
      'time_entries',
      {'is_submitted': 1},
      where: 'id IN (${ids.map((_) => '?').join(', ')})',
      whereArgs: ids,
    );
  }

  // Get a single time entry by ID
  Future<TimeEntry?> getTimeEntryById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'time_entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TimeEntry.fromMap(maps.first);
    }
    return null;
  }

  // Get all time entries
  Future<List<TimeEntry>> getAllTimeEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('time_entries');
    return List.generate(maps.length, (i) => TimeEntry.fromMap(maps[i]));
  }

  // Get time entries for a date range
  Future<List<TimeEntry>> getTimeEntriesInDateRange(
      DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'time_entries',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toString().split(' ')[0],
        endDate.toString().split(' ')[0]
      ],
    );
    return List.generate(maps.length, (i) => TimeEntry.fromMap(maps[i]));
  }

  // Get non-submitted time entries for a date range
  Future<List<TimeEntry>> getNonSubmittedTimeEntriesInDateRange(
      DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'time_entries',
      where: 'date BETWEEN ? AND ? AND is_submitted = 0',
      whereArgs: [
        startDate.toString().split(' ')[0],
        endDate.toString().split(' ')[0]
      ],
    );
    return List.generate(maps.length, (i) => TimeEntry.fromMap(maps[i]));
  }

  // Get total hours for a specific client
  Future<double> getTotalHoursForClient(String clientName) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(hours) as total FROM time_entries WHERE client_name = ?',
      [clientName],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // Get total hours grouped by month
  Future<Map<String, double>> getTotalHoursByMonth() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT substr(date, 6, 2) as month, SUM(hours) as total FROM time_entries GROUP BY month',
    );

    final Map<String, double> monthlySums = {};
    for (var row in result) {
      monthlySums[row['month'] as String] = row['total'] as double? ?? 0.0;
    }
    return monthlySums;
  }

  // Get total hours for current quarter
  Future<double> getTotalHoursForQuarter(int quarter, int year) async {
    final db = await database;

    // Define start and end months for the quarter
    int startMonth = (quarter - 1) * 3 + 1;
    int endMonth = quarter * 3;

    final result = await db.rawQuery(
      '''
      SELECT SUM(hours) as total 
      FROM time_entries 
      WHERE substr(date, 1, 4) = ? AND 
      CAST(substr(date, 6, 2) as INTEGER) BETWEEN ? AND ?
      ''',
      [year.toString(), startMonth, endMonth],
    );

    return result.first['total'] as double? ?? 0.0;
  }

  // Get all clients
  Future<List<String>> getAllClients() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT client_name FROM time_entries ORDER BY client_name',
    );
    return result.map((row) => row['client_name'] as String).toList();
  }

  // Get all projects
  Future<List<String>> getAllProjects() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT project_name FROM time_entries ORDER BY project_name',
    );
    return result.map((row) => row['project_name'] as String).toList();
  }

  // Get total hours by project
  Future<Map<String, double>> getTotalHoursByProject() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT project_name, SUM(hours) as total FROM time_entries GROUP BY project_name ORDER BY total DESC',
    );

    final Map<String, double> projectSums = {};
    for (var row in result) {
      projectSums[row['project_name'] as String] =
          row['total'] as double? ?? 0.0;
    }
    return projectSums;
  }

  // Get hours by day of week (productivity pattern)
  Future<Map<String, double>> getHoursByDayOfWeek() async {
    final db = await database;
    // SQLite's strftime('%w') returns day of week 0-6 with 0 being Sunday
    final result = await db.rawQuery('''
      SELECT 
        CASE CAST(strftime('%w', date) AS INTEGER)
          WHEN 0 THEN 'Sunday'
          WHEN 1 THEN 'Monday'
          WHEN 2 THEN 'Tuesday'
          WHEN 3 THEN 'Wednesday'
          WHEN 4 THEN 'Thursday'
          WHEN 5 THEN 'Friday'
          WHEN 6 THEN 'Saturday'
        END as day_of_week,
        SUM(hours) as total 
      FROM time_entries 
      GROUP BY day_of_week 
      ORDER BY CAST(strftime('%w', date) AS INTEGER)
    ''');

    final Map<String, double> dayOfWeekSums = {};
    for (var row in result) {
      dayOfWeekSums[row['day_of_week'] as String] =
          row['total'] as double? ?? 0.0;
    }
    return dayOfWeekSums;
  }

  // Get average daily hours over time (trend analysis)
  Future<Map<String, double>> getAverageDailyHoursByMonth() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        substr(date, 1, 7) as month,
        SUM(hours) as total_hours,
        COUNT(DISTINCT date) as days_worked,
        ROUND(SUM(hours) / COUNT(DISTINCT date), 2) as avg_daily_hours
      FROM time_entries 
      GROUP BY month 
      ORDER BY month
    ''');

    final Map<String, double> avgDailyHours = {};
    for (var row in result) {
      avgDailyHours[row['month'] as String] =
          row['avg_daily_hours'] as double? ?? 0.0;
    }
    return avgDailyHours;
  }

  // Get billable vs non-billable hours ratio
  Future<Map<String, double>> getBillableVsNonBillableHours() async {
    final db = await database;
    final billableResult = await db.rawQuery(
      'SELECT SUM(hours) as total FROM time_entries WHERE is_billable = 1',
    );
    final nonBillableResult = await db.rawQuery(
      'SELECT SUM(hours) as total FROM time_entries WHERE is_billable = 0',
    );

    return {
      'Billable': billableResult.first['total'] as double? ?? 0.0,
      'Non-Billable': nonBillableResult.first['total'] as double? ?? 0.0,
    };
  }

  // Get most time-consuming tasks
  Future<List<Map<String, dynamic>>> getMostTimeConsumingTasks(
      int limit) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        task_name, 
        SUM(hours) as total_hours
      FROM time_entries 
      GROUP BY task_name 
      ORDER BY total_hours DESC 
      LIMIT ?
    ''', [limit]);

    return result;
  }

  // Get productivity score (hours per day compared to personal average)
  Future<Map<String, dynamic>> getProductivityMetrics() async {
    final db = await database;

    // Average hours per day
    final avgResult = await db.rawQuery('''
      SELECT 
        ROUND(SUM(hours) / COUNT(DISTINCT date), 2) as avg_hours_per_day
      FROM time_entries
    ''');

    // Most productive day
    final mostProductiveResult = await db.rawQuery('''
      SELECT 
        date, 
        SUM(hours) as total_hours
      FROM time_entries 
      GROUP BY date 
      ORDER BY total_hours DESC 
      LIMIT 1
    ''');

    // Total days worked
    final daysWorkedResult = await db.rawQuery('''
      SELECT 
        COUNT(DISTINCT date) as days_worked
      FROM time_entries
    ''');

    return {
      'avgHoursPerDay': avgResult.first['avg_hours_per_day'] as double? ?? 0.0,
      'mostProductiveDay': mostProductiveResult.isEmpty
          ? null
          : {
              'date': mostProductiveResult.first['date'] as String,
              'hours':
                  mostProductiveResult.first['total_hours'] as double? ?? 0.0,
            },
      'daysWorked': daysWorkedResult.first['days_worked'] as int? ?? 0,
    };
  }

  // Settings methods
  Future<Map<String, dynamic>> getSettings() async {
    final db = await database;
    
    try {
      // Check if settings table exists
      final tableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'"
      );
      
      if (tableCheck.isEmpty) {
        if (kDebugMode) debugPrint('Settings table does not exist, creating it...');
        // This should only happen during development or if somehow
        // the migration failed. In production, tables should be
        // created during the normal migration process.
        await db.execute('''
          CREATE TABLE IF NOT EXISTS settings(
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        
        // Insert default settings
        await db.insert('settings', {'key': 'dark_mode', 'value': '0'});
        await db.insert('settings', {'key': 'default_currency', 'value': 'USD'});
        await db.insert('settings', {'key': 'default_hours_per_day', 'value': '8'});
        await db.insert('settings', {'key': 'auto_backup', 'value': '0'});
      }
      
      final settings = await db.query('settings');
      
      Map<String, dynamic> result = {};
      for (var setting in settings) {
        final key = setting['key'] as String;
        final value = setting['value'] as String;
        
        // Convert values to appropriate types
        if (key == 'dark_mode' || key == 'auto_backup') {
          result[key] = int.tryParse(value) ?? 0;
        } else if (key == 'default_hours_per_day') {
          result[key] = int.tryParse(value) ?? 8;
        } else {
          result[key] = value;
        }
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting settings: $e');
      // Return default settings
      return {
        'dark_mode': 0,
        'default_currency': 'USD',
        'default_hours_per_day': 8,
        'auto_backup': 0,
      };
    }
  }
  
  Future<void> saveSetting(String key, dynamic value) async {
    final db = await database;
    
    try {
      // Check if settings table exists
      final tableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'"
      );
      
      if (tableCheck.isEmpty) {
        if (kDebugMode) debugPrint('Settings table does not exist, creating it...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS settings(
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      }
      
      // Convert value to string for storage
      String stringValue;
      if (value is bool) {
        stringValue = value ? '1' : '0';
      } else {
        stringValue = value.toString();
      }
      
      // Insert or update the setting
      await db.insert(
        'settings',
        {'key': key, 'value': stringValue},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving setting: $e');
    }
  }
  
  // Client methods
  Future<List<Map<String, dynamic>>> getClients() async {
    final db = await database;
    return await db.query('clients', orderBy: 'name');
  }
  
  Future<int> saveClient(Map<String, dynamic> client) async {
    final db = await database;
    
    if (client.containsKey('id') && client['id'] != null) {
      // Update existing client
      await db.update(
        'clients',
        client,
        where: 'id = ?',
        whereArgs: [client['id']],
      );
      return client['id'];
    } else {
      // Insert new client
      client['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('clients', client);
    }
  }
  
  // Project methods
  Future<List<Map<String, dynamic>>> getProjects({int? clientId}) async {
    final db = await database;
    
    if (clientId != null) {
      return await db.query(
        'projects',
        where: 'client_id = ?',
        whereArgs: [clientId],
        orderBy: 'name',
      );
    } else {
      return await db.rawQuery('''
        SELECT p.*, c.name as client_name
        FROM projects p
        LEFT JOIN clients c ON p.client_id = c.id
        ORDER BY c.name, p.name
      ''');
    }
  }
  
  Future<int> saveProject(Map<String, dynamic> project) async {
    final db = await database;
    
    if (project.containsKey('id') && project['id'] != null) {
      // Update existing project
      await db.update(
        'projects',
        project,
        where: 'id = ?',
        whereArgs: [project['id']],
      );
      return project['id'];
    } else {
      // Insert new project
      project['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('projects', project);
    }
  }
  
  // Task methods
  Future<List<Map<String, dynamic>>> getTasks({int? projectId}) async {
    final db = await database;
    
    if (projectId != null) {
      return await db.query(
        'tasks',
        where: 'project_id = ?',
        whereArgs: [projectId],
        orderBy: 'name',
      );
    } else {
      return await db.rawQuery('''
        SELECT t.*, p.name as project_name, c.name as client_name
        FROM tasks t
        LEFT JOIN projects p ON t.project_id = p.id
        LEFT JOIN clients c ON p.client_id = c.id
        ORDER BY c.name, p.name, t.name
      ''');
    }
  }
  
  Future<int> saveTask(Map<String, dynamic> task) async {
    final db = await database;
    
    if (task.containsKey('id') && task['id'] != null) {
      // Update existing task
      await db.update(
        'tasks',
        task,
        where: 'id = ?',
        whereArgs: [task['id']],
      );
      return task['id'];
    } else {
      // Insert new task
      task['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('tasks', task);
    }
  }

  // Get the database file for export
  Future<File> getDatabaseFile() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return File(path);
  }
  
  // Import database from a file
  Future<void> importDatabase(File importFile) async {
    try {
      // Close the current database connection
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Get path to the actual database
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String dbPath = join(documentsDirectory.path, _databaseName);
      File dbFile = File(dbPath);
      
      // Delete the current database file
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      
      // Copy the import file to the database path
      await importFile.copy(dbPath);
      
      // Reopen the database
      _database = await _initDatabase();
      
      if (kDebugMode) debugPrint('Database imported successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('Error importing database: $e');
      rethrow;
    }
  }
}
