import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../constants/app_constants.dart';
import '../providers/time_entry_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  Map<String, double> _clientHoursData = {};
  Map<String, double> _projectHoursData = {};
  Map<String, double> _dayOfWeekData = {};
  Map<String, double> _billableVsNonBillable = {};
  List<Map<String, dynamic>> _topTasks = [];
  Map<String, dynamic> _productivityMetrics = {};
  double _currentMonthHours = 0;
  double _currentQuarterHours = 0;
  double _currentYearHours = 0;
  final int _currentMonth = DateTime.now().month;
  final int _currentYear = DateTime.now().year;
  final int _currentQuarter = ((DateTime.now().month - 1) ~/ 3) + 1;
  
  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }
  
  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });
    
    final timeEntryProvider = Provider.of<TimeEntryProvider>(context, listen: false);
    
    try {
      // Get current month hours
      _currentMonthHours = await timeEntryProvider.getTotalHoursForMonth(_currentMonth, _currentYear);
      
      // Get current quarter hours
      _currentQuarterHours = await timeEntryProvider.getTotalHoursForQuarter(_currentQuarter, _currentYear);
      
      // Get current year hours
      _currentYearHours = await timeEntryProvider.getTotalHoursForYear(_currentYear);
      
      // Get hours by client
      final clients = await timeEntryProvider.getAllClients();
      final Map<String, double> clientHours = {};
      
      for (final client in clients) {
        double hours = await timeEntryProvider.getTotalHoursForClient(client);
        clientHours[client] = hours;
      }
      
      // Get hours by project
      _projectHoursData = await timeEntryProvider.getTotalHoursByProject();
      
      // Get hours by day of week
      _dayOfWeekData = await timeEntryProvider.getHoursByDayOfWeek();
      
      // Get billable vs non-billable hours
      _billableVsNonBillable = await timeEntryProvider.getBillableVsNonBillableHours();
      
      // Get most time-consuming tasks
      _topTasks = await timeEntryProvider.getMostTimeConsumingTasks(5);
      
      // Get productivity metrics
      _productivityMetrics = await timeEntryProvider.getProductivityMetrics();
      
      setState(() {
        _clientHoursData = clientHours;
        _isLoading = false;
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Period summaries
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Time Summaries',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingMd),
                          _buildSummaryTile(
                            'Current Month',
                            DateFormat('MMMM yyyy').format(DateTime(_currentYear, _currentMonth)),
                            _currentMonthHours,
                          ),
                          const Divider(),
                          _buildSummaryTile(
                            'Current Quarter',
                            'Q$_currentQuarter $_currentYear',
                            _currentQuarterHours,
                          ),
                          const Divider(),
                          _buildSummaryTile(
                            'Current Year',
                            _currentYear.toString(),
                            _currentYearHours,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  
                  // Client distribution
                  if (_clientHoursData.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hours by Client',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                            SizedBox(
                              height: 300,
                              child: _buildPieChart(),
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                            ..._buildClientLegend(),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppConstants.spacingMd),
                        child: Center(
                          child: Text('No client data available'),
                        ),
                      ),
                    ),
                  ],
                  
                  // Day of week distribution
                  if (_dayOfWeekData.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hours by Day of Week',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                            SizedBox(
                              height: 300,
                              child: _buildDayOfWeekChart(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppConstants.spacingMd),
                        child: Center(
                          child: Text('No day of week data available'),
                        ),
                      ),
                    ),
                  ],
                  
                  // Billable vs non-billable distribution
                  if (_billableVsNonBillable.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Billable vs Non-Billable Hours',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                            SizedBox(
                              height: 300,
                              child: _buildBillableChart(),
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                            ..._buildBillableLegend(),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppConstants.spacingMd),
                        child: Center(
                          child: Text('No billable vs non-billable data available'),
                        ),
                      ),
                    ),
                  ],
                  
                  // Project distribution
                  if (_projectHoursData.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hours by Project',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                            SizedBox(
                              height: 300,
                              child: _buildProjectsChart(),
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                            ..._buildProjectLegend(),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppConstants.spacingMd),
                        child: Center(
                          child: Text('No project data available'),
                        ),
                      ),
                    ),
                  ],
                  
                  // Productivity metrics
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Productivity Insights',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingMd),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Average Hours Per Day'),
                            trailing: Text(
                              '${_productivityMetrics['avgHoursPerDay']?.toStringAsFixed(1) ?? '0.0'} hrs',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Divider(),
                          if (_productivityMetrics['mostProductiveDay'] != null) ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Most Productive Day'),
                              subtitle: Text(_productivityMetrics['mostProductiveDay']['date'] ?? ''),
                              trailing: Text(
                                '${_productivityMetrics['mostProductiveDay']['hours']?.toStringAsFixed(1) ?? '0.0'} hrs',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Divider(),
                          ],
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Total Days Worked'),
                            trailing: Text(
                              '${_productivityMetrics['daysWorked'] ?? '0'} days',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Most time-consuming tasks
                  if (_topTasks.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Most Time-Consuming Tasks',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                            ..._topTasks.map((task) => Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(task['task_name'] as String),
                                  trailing: Text(
                                    '${(task['total_hours'] as double?)?.toStringAsFixed(1) ?? '0.0'} hrs',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (_topTasks.last != task) const Divider(),
                              ],
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
  
  Widget _buildSummaryTile(String title, String subtitle, double hours) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        '${hours.toStringAsFixed(1)} hrs',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildPieChart() {
    final List<Color> colorList = [
      Colors.blue,
      Colors.red,
      Colors.green, 
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.lime,
    ];
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _getChartSections(colorList),
      ),
    );
  }
  
  List<PieChartSectionData> _getChartSections(List<Color> colorList) {
    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    
    // Calculate total hours
    final totalHours = _clientHoursData.values.fold(
      0.0, (double sum, double hours) => sum + hours);
    
    _clientHoursData.forEach((client, hours) {
      final percentage = totalHours > 0 ? (hours / totalHours) * 100 : 0;
      
      sections.add(
        PieChartSectionData(
          color: colorList[colorIndex % colorList.length],
          value: hours,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      
      colorIndex++;
    });
    
    return sections;
  }
  
  List<Widget> _buildClientLegend() {
    final List<Color> colorList = [
      Colors.blue,
      Colors.red,
      Colors.green, 
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.lime,
    ];
    
    final List<Widget> legendItems = [];
    int colorIndex = 0;
    
    _clientHoursData.forEach((client, hours) {
      legendItems.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: colorList[colorIndex % colorList.length],
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(client)),
              Text('${hours.toStringAsFixed(1)} hrs'),
            ],
          ),
        ),
      );
      
      colorIndex++;
    });
    
    return legendItems;
  }
  
  // New method to build bar chart for day of week data
  Widget _buildDayOfWeekChart() {
    final List<Color> colorList = [
      Colors.blue.shade300,
      Colors.blue.shade400,
      Colors.blue.shade500,
      Colors.blue.shade600,
      Colors.blue.shade700,
      Colors.blue.shade800,
      Colors.blue.shade900,
    ];
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _dayOfWeekData.values.isEmpty ? 10 : 
             (_dayOfWeekData.values.reduce((a, b) => a > b ? a : b) * 1.2),
        barTouchData: BarTouchData(
          enabled: true,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                String text = '';
                if (value < _dayOfWeekData.length) {
                  text = _dayOfWeekData.keys.elementAt(value.toInt())[0];
                }
                return Text(text);
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: List.generate(_dayOfWeekData.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: _dayOfWeekData.values.elementAt(index),
                color: colorList[index % colorList.length],
                width: 22,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
  
  // New method to build billable vs non-billable chart
  Widget _buildBillableChart() {
    final List<Color> colorList = [
      Colors.green,
      Colors.red,
    ];
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _getBillableChartSections(colorList),
      ),
    );
  }
  
  List<PieChartSectionData> _getBillableChartSections(List<Color> colorList) {
    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    
    // Calculate total hours
    final totalHours = _billableVsNonBillable.values.fold(
      0.0, (double sum, double hours) => sum + hours);
    
    _billableVsNonBillable.forEach((type, hours) {
      final percentage = totalHours > 0 ? (hours / totalHours) * 100 : 0;
      
      sections.add(
        PieChartSectionData(
          color: colorList[colorIndex % colorList.length],
          value: hours,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      
      colorIndex++;
    });
    
    return sections;
  }
  
  // New method to build project hours chart
  Widget _buildProjectsChart() {
    final List<Color> colorList = [
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
    ];
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _getProjectChartSections(colorList),
      ),
    );
  }
  
  List<PieChartSectionData> _getProjectChartSections(List<Color> colorList) {
    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    
    // Calculate total hours
    final totalHours = _projectHoursData.values.fold(
      0.0, (double sum, double hours) => sum + hours);
    
    _projectHoursData.forEach((project, hours) {
      final percentage = totalHours > 0 ? (hours / totalHours) * 100 : 0;
      
      sections.add(
        PieChartSectionData(
          color: colorList[colorIndex % colorList.length],
          value: hours,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      
      colorIndex++;
    });
    
    return sections;
  }
  
  // Helper to build project legend
  List<Widget> _buildProjectLegend() {
    final List<Color> colorList = [
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
    ];
    
    final List<Widget> legendItems = [];
    int colorIndex = 0;
    
    _projectHoursData.forEach((project, hours) {
      legendItems.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: colorList[colorIndex % colorList.length],
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(project)),
              Text('${hours.toStringAsFixed(1)} hrs'),
            ],
          ),
        ),
      );
      
      colorIndex++;
    });
    
    return legendItems;
  }
  
  // Helper to build billable legend
  List<Widget> _buildBillableLegend() {
    final List<Color> colorList = [
      Colors.green,
      Colors.red,
    ];
    
    final List<Widget> legendItems = [];
    int colorIndex = 0;
    
    _billableVsNonBillable.forEach((type, hours) {
      legendItems.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: colorList[colorIndex % colorList.length],
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(type)),
              Text('${hours.toStringAsFixed(1)} hrs'),
            ],
          ),
        ),
      );
      
      colorIndex++;
    });
    
    return legendItems;
  }
}
