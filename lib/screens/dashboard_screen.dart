import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';
import '../providers/time_entry_provider.dart';
import '../providers/client_provider.dart';
import '../providers/project_provider.dart';
import 'time_entry_form_screen.dart';
import 'entries_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  double _todayHours = 0;
  double _weekHours = 0;
  double _monthHours = 0;
  double _yearHours = 0;
  List<Map<String, dynamic>> _recentEntries = [];
  int _activeClientsCount = 0;
  int _activeProjectsCount = 0;
  
  @override
  void initState() {
    super.initState();
    // Schedule _loadData after the current build frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final timeEntryProvider = Provider.of<TimeEntryProvider>(context, listen: false);
      final clientProvider = Provider.of<ClientProvider>(context, listen: false);
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      
      // Today's hours
      _todayHours = await timeEntryProvider.getTotalHoursForDay(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
      
      // This week's hours (starting from Monday)
      final startOfWeek = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - DateTime.now().weekday + 1);
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      _weekHours = await timeEntryProvider.getTotalHoursForDateRange(startOfWeek, endOfWeek);
      
      // This month's hours
      final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final endOfMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
      _monthHours = await timeEntryProvider.getTotalHoursForDateRange(startOfMonth, endOfMonth);
      
      // This year's hours
      final startOfYear = DateTime(DateTime.now().year, 1, 1);
      final endOfYear = DateTime(DateTime.now().year, 12, 31, 23, 59, 59);
      _yearHours = await timeEntryProvider.getTotalHoursForDateRange(startOfYear, endOfYear);
      
      // Recent entries - limit to 3
      _recentEntries = await timeEntryProvider.getRecentEntries(3);
      
      // Active clients and projects
      _activeClientsCount = clientProvider.clients.length;
      _activeProjectsCount = projectProvider.projects.length;
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billable'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _navigateToScreen(const SettingsScreen()),
            tooltip: 'Settings',
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDarkMode ? Colors.grey[900]! : Colors.grey[50]!,
                isDarkMode ? Colors.grey[850]! : Colors.white,
              ],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppConstants.primaryColor,
                      AppConstants.primaryColor.withAlpha(230),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Billable',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Time Tracking & Invoicing',
                      style: TextStyle(
                        color: Colors.white.withAlpha(204),
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: Colors.white.withAlpha(153),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 0,
                color: Colors.transparent,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: const Icon(Icons.dashboard_outlined, color: AppConstants.primaryColor),
                  title: const Text('Dashboard'),
                  selected: true,
                  selectedTileColor: AppConstants.primaryColor.withAlpha(25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Card(
                elevation: 0,
                color: Colors.transparent,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(Icons.timer_outlined, color: Colors.greenAccent[400]),
                  title: const Text('Add Time Entry'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToScreen(TimeEntryFormScreen());
                  },
                ),
              ),
              Card(
                elevation: 0,
                color: Colors.transparent,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(Icons.list_alt_outlined, color: Colors.orangeAccent[400]),
                  title: const Text('View Entries'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToScreen(const EntriesScreen());
                  },
                ),
              ),
              Card(
                elevation: 0,
                color: Colors.transparent,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(Icons.bar_chart_outlined, color: Colors.purpleAccent[400]),
                  title: const Text('Statistics'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToScreen(const StatisticsScreen());
                  },
                ),
              ),
              Card(
                elevation: 0,
                color: Colors.transparent,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(Icons.cloud_download_outlined, color: Colors.tealAccent[400]),
                  title: const Text('Export'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Export functionality coming soon!'),
                      ),
                    );
                  },
                ),
              ),
              Card(
                elevation: 0,
                color: Colors.transparent,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(Icons.settings_outlined, color: Colors.blueGrey[400]),
                  title: const Text('Settings'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToScreen(const SettingsScreen());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 16,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Time Tracking Progress Card - redesigned with unified style
                    Card(
                      elevation: 1.5,
                      shadowColor: AppConstants.primaryColor.withAlpha(76), // Match dashboard cards
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppConstants.primaryColor.withAlpha(13),
                          width: 1,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppConstants.primaryColor.withAlpha(8),
                              AppConstants.primaryColor.withAlpha(18),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Today progress
                            _buildTimeProgressBar(
                              'Today',
                              0, // keeping parameter for backward compatibility 
                              24.0,
                              _todayHours,
                              Colors.amber,
                              textColor,
                              subtitleColor,
                            ),
                            const SizedBox(height: 8),
                            
                            // This week progress
                            _buildTimeProgressBar(
                              'This week',
                              0, // keeping parameter for backward compatibility 
                              168.0,
                              _weekHours,
                              Colors.purple[300]!,
                              textColor,
                              subtitleColor,
                            ),
                            const SizedBox(height: 8),
                            
                            // This month progress
                            _buildTimeProgressBar(
                              'This month',
                              0, // keeping parameter for backward compatibility 
                              DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day * 24.0,
                              _monthHours,
                              Colors.purple[500]!,
                              textColor,
                              subtitleColor,
                            ),
                            const SizedBox(height: 8),
                            
                            // This year progress
                            _buildTimeProgressBar(
                              'This year',
                              0, // keeping parameter for backward compatibility 
                              ((DateTime.now().year % 4 == 0) ? 366 : 365) * 24.0,
                              _yearHours,
                              Colors.purple[700]!,
                              textColor,
                              subtitleColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Unified Dashboard Cards - sleek grid layout of all 6 cards
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Modern section header with accent line
                        AppConstants.sectionHeader('Dashboard', context: context),
                        const SizedBox(height: 12),
                        
                        // First row - Stats cards with unified design
                        Row(
                          children: [
                            Expanded(
                              child: _buildDashboardCard(
                                Icons.people_outline,
                                _activeClientsCount.toString(),
                                'Active Clients',
                                AppConstants.primaryColor.withAlpha(204), // 0.8 opacity
                                cardColor,
                                textColor,
                                subtitleColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDashboardCard(
                                Icons.folder_outlined,
                                _activeProjectsCount.toString(),
                                'Active Projects',
                                AppConstants.primaryColor,
                                cardColor,
                                textColor,
                                subtitleColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDashboardCard(
                                Icons.access_time,
                                _monthHours.toStringAsFixed(1),
                                'Hours This Month',
                                AppConstants.primaryColor.withAlpha(230), // 0.9 opacity
                                cardColor,
                                textColor,
                                subtitleColor,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Second row - Action cards with unified design
                        Row(
                          children: [
                            Expanded(
                              child: _buildDashboardCard(
                                Icons.add_circle_outline,
                                'Add Entry',
                                '',
                                Colors.greenAccent[400]!,
                                cardColor,
                                textColor,
                                subtitleColor,
                                onTap: () => _navigateToScreen(TimeEntryFormScreen()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDashboardCard(
                                Icons.list_alt_outlined,
                                'View All',
                                '',
                                Colors.orangeAccent[400]!,
                                cardColor,
                                textColor,
                                subtitleColor,
                                onTap: () => _navigateToScreen(const EntriesScreen()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDashboardCard(
                                Icons.bar_chart_outlined,
                                'Statistics',
                                '',
                                Colors.purpleAccent[400]!,
                                cardColor,
                                textColor,
                                subtitleColor,
                                onTap: () => _navigateToScreen(const StatisticsScreen()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Recent entries
                    // Modern section header with accent line for Recent Activity
                    AppConstants.sectionHeader('Recent Activity', context: context),
                    const SizedBox(height: 12),
                    _recentEntries.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.hourglass_empty_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No recent entries',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: _recentEntries.map((entry) {
                              final date = DateTime.parse(entry['date']);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 1.5,
                                shadowColor: AppConstants.primaryColor.withAlpha(38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isDarkMode 
                                        ? AppConstants.primaryColor.withAlpha(20)
                                        : AppConstants.primaryColor.withAlpha(13),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  title: Text(
                                    '${entry['client_name']} - ${entry['task_name']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(entry['project_name']),
                                      Text(
                                        DateFormat('MMM d, yyyy').format(date),
                                        style: TextStyle(
                                          color: isDarkMode 
                                              ? Colors.grey[400] 
                                              : Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? AppConstants.primaryColor.withAlpha(51)
                                          : AppConstants.primaryColor.withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${entry['hours']} hrs',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? AppConstants.primaryColor
                                            : AppConstants.primaryColor,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    _navigateToScreen(const EntriesScreen());
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
  
  // Updated progress bar with a cleaner, more minimalist design without elapsed time indicators
  Widget _buildTimeProgressBar(
    String label, 
    double elapsedValue, // keeping parameter for backward compatibility 
    double maxValue, 
    double trackedValue,
    Color color,
    Color? textColor,
    Color? subtitleColor,
  ) {
    // Calculate progress as simple percentage of target
    final progress = trackedValue / maxValue > 1.0 ? 1.0 : trackedValue / maxValue;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: subtitleColor ?? Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            // Background track (simplified)
            Container(
              height: 5, // Even slimmer bar for cleaner look
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(25), // More subtle background
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            // Tracked time indicator (just one clean bar)
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 5, // Even slimmer bar for cleaner look
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2.5),
                  // Subtle glow effect for a premium feel
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(30),
                      blurRadius: 2,
                      offset: const Offset(0, 0),
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Updated method for building unified dashboard cards (stats and actions)
  Widget _buildDashboardCard(
    IconData icon,
    String title,
    String subtitle,
    Color accentColor,
    Color? backgroundColor,
    Color? textColor,
    Color? subtitleColor, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 1.5,
      shadowColor: accentColor.withAlpha(76),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Match card shape
        side: BorderSide(
          color: accentColor.withAlpha(13),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16), // Match card shape
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withAlpha(8),
                accentColor.withAlpha(18),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 30,
                color: accentColor,
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              if (subtitle.isNotEmpty) 
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
