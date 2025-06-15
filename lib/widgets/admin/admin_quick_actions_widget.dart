import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutrigen/services/admin_service.dart';
import 'package:nutrigen/screens/admin/admin_users_screen.dart';
import 'package:nutrigen/screens/admin/admin_settings_screen.dart';
import 'package:nutrigen/screens/admin/admin_analytics_screen.dart';

class AdminQuickActionsWidget extends StatefulWidget {
  final Function? onRefreshRequired;

  const AdminQuickActionsWidget({Key? key, this.onRefreshRequired})
    : super(key: key);

  @override
  State<AdminQuickActionsWidget> createState() =>
      _AdminQuickActionsWidgetState();
}

class _AdminQuickActionsWidgetState extends State<AdminQuickActionsWidget> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Color(0xFFCC1C14)),
              const SizedBox(width: 12),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Navigation actions
          _buildActionSection('Navigation', [
            _buildActionButton(
              'Manage Users',
              'View and manage all users',
              Icons.people,
              Colors.blue,
              () => _navigateToUsers(context),
            ),
            _buildActionButton(
              'Analytics',
              'View detailed analytics',
              Icons.analytics,
              Colors.green,
              () => _navigateToAnalytics(context),
            ),
            _buildActionButton(
              'System Settings',
              'Configure system settings',
              Icons.settings,
              Colors.orange,
              () => _navigateToSettings(context),
            ),
          ]),

          const SizedBox(height: 20),

          // System actions
          _buildActionSection('System Operations', [
            _buildActionButton(
              'Refresh Data',
              'Reload all dashboard data',
              Icons.refresh,
              Colors.purple,
              () => _refreshData(),
            ),
            _buildActionButton(
              'System Health',
              'Check system status',
              Icons.health_and_safety,
              Colors.teal,
              () => _checkSystemHealth(),
            ),
            _buildActionButton(
              'Export Data',
              'Export system data',
              Icons.download,
              Colors.indigo,
              () => _exportData(),
            ),
          ]),

          const SizedBox(height: 20),

          // Quick stats
          _buildQuickStatsSection(),
        ],
      ),
    );
  }

  Widget _buildActionSection(String title, List<Widget> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Column(children: actions),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStatItem('Today', '12', 'Signups', Colors.blue),
              _buildQuickStatItem('Active', '45', 'Users', Colors.green),
              _buildQuickStatItem('System', '99%', 'Uptime', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  void _navigateToUsers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminUsersScreen()),
    );
  }

  void _navigateToAnalytics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminAnalyticsScreen()),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminSettingsScreen()),
    );
  }

  Future<void> _refreshData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Refreshing data...'),
                ],
              ),
            ),
      );

      // Simulate refresh delay
      await Future.delayed(const Duration(seconds: 2));

      Navigator.of(context).pop(); // Close loading dialog

      // Call refresh callback if provided
      if (widget.onRefreshRequired != null) {
        widget.onRefreshRequired!();
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data refreshed successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkSystemHealth() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Checking system health...'),
                ],
              ),
            ),
      );

      final health = await _adminService.getSystemHealth();

      Navigator.of(context).pop(); // Close loading dialog

      final databaseHealth = health['database'] == 'healthy';
      final ngrokHealth = health['ngrok'] == 'healthy';

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('System Health Report'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHealthStatusItem('Database', databaseHealth),
                  const SizedBox(height: 8),
                  _buildHealthStatusItem('Ngrok API', ngrokHealth),
                  const SizedBox(height: 16),
                  Text(
                    'Last checked: ${DateTime.now().toString().split('.')[0]}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking system health: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildHealthStatusItem(String service, bool isHealthy) {
    return Row(
      children: [
        Icon(
          isHealthy ? Icons.check_circle : Icons.error,
          color: isHealthy ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text('$service: '),
        Text(
          isHealthy ? 'Healthy' : 'Error',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isHealthy ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Future<void> _exportData() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Export Data'),
            content: const Text('Choose the type of data you want to export:'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _performExport('users');
                },
                child: const Text('User Data'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _performExport('analytics');
                },
                child: const Text('Analytics'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _performExport('all');
                },
                child: const Text('All Data'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _performExport(String type) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text('Exporting $type data...'),
                ],
              ),
            ),
      );

      // Simulate export process
      await Future.delayed(const Duration(seconds: 3));

      Navigator.of(context).pop(); // Close loading dialog

      // Generate mock export data
      final exportData = _generateExportData(type);

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: exportData));

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Export Complete'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 16),
                  Text('$type data has been exported and copied to clipboard.'),
                  const SizedBox(height: 8),
                  Text(
                    'You can paste it into a spreadsheet or text editor.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateExportData(String type) {
    final timestamp = DateTime.now().toString().split('.')[0];

    switch (type) {
      case 'users':
        return '''
NutriGen User Export - $timestamp
================================
User ID, Name, Email, Verified, Onboarding Complete, Join Date
user_001, John Doe, john@example.com, true, true, 2024-01-15
user_002, Jane Smith, jane@example.com, true, false, 2024-01-16
user_003, Bob Johnson, bob@example.com, false, false, 2024-01-17
        ''';

      case 'analytics':
        return '''
NutriGen Analytics Export - $timestamp
====================================
Metric, Value, Date
Total Users, 150, $timestamp
Daily Signups, 12, $timestamp
Meal Plans Generated, 450, $timestamp
Active Users, 85, $timestamp
        ''';

      case 'all':
        return '''
NutriGen Complete Data Export - $timestamp
=========================================

USERS:
User ID, Name, Email, Verified, Complete
user_001, John Doe, john@example.com, true, true
user_002, Jane Smith, jane@example.com, true, false

ANALYTICS:
Metric, Value
Total Users, 150
Daily Signups, 12
Meal Plans, 450

SYSTEM HEALTH:
Component, Status
Database, Healthy
Ngrok API, Healthy
        ''';

      default:
        return 'Export data for $type - $timestamp';
    }
  }
}

// Utility widget for admin floating action button
class AdminFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AdminFloatingActionButton({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed ?? () => _showQuickActions(context),
      backgroundColor: const Color(0xFFCC1C14),
      foregroundColor: Colors.white,
      child: const Icon(Icons.admin_panel_settings),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              builder:
                  (context, scrollController) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Admin Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: const AdminQuickActionsWidget(),
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
    );
  }
}
