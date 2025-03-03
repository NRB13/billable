// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/database_service.dart';
import 'providers/time_entry_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/client_provider.dart';
import 'providers/project_provider.dart';
import 'providers/task_provider.dart';
import 'screens/dashboard_screen.dart';
import 'constants/app_constants.dart';

void main() async {
  // Ensure Flutter is initialized before using platform channels
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final db = DatabaseService();
  await db.database;
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TimeEntryProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => ClientProvider()),
        ChangeNotifierProvider(create: (context) => ProjectProvider()),
        ChangeNotifierProvider(create: (context) => TaskProvider()),
      ],
      child: const BillableApp(),
    ),
  );
}

class BillableApp extends StatelessWidget {
  const BillableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Billable',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            primaryColor: AppConstants.primaryColor,
            // Using theme-specific properties directly
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: AppConstants.primaryButtonStyle,
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: AppConstants.secondaryButtonStyle,
            ),
            listTileTheme: AppConstants.unifiedListTileTheme(),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            primaryColor: AppConstants.primaryColor,
            // Using theme-specific properties directly
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: AppConstants.primaryButtonStyle,
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: AppConstants.secondaryButtonStyle,
            ),
            listTileTheme: AppConstants.unifiedListTileTheme(),
          ),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          home: const DashboardScreen(),
        );
      }
    );
  }
}
