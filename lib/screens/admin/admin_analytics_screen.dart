import 'package:flutter/material.dart';
import 'package:nutrigen/services/admin_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();

  Map<String, dynamic>? _chartData;
  Map<String, dynamic>? _recentActivity;
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = true;
  String _errorMessage = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final results = await Future.wait([
        _adminService.getChartData(),
        _adminService.getRecentActivity(),
        _adminService.getDashboardStats(),
      ]);

      setState(() {
        _chartData = results[0];
        _recentActivity = results[1];
        _dashboardStats = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: const Color(0xFFCC1C14),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Charts', icon: Icon(Icons.bar_chart, size: 20)),
            Tab(text: 'Activity', icon: Icon(Icons.timeline, size: 20)),
            Tab(text: 'Reports', icon: Icon(Icons.analytics, size: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading analytics',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(_errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAnalyticsData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildChartsTab(),
                  _buildActivityTab(),
                  _buildReportsTab(),
                ],
              ),
    );
  }

  Widget _buildChartsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly trends chart
            _buildWeeklyTrendsCard(),
            const SizedBox(height: 16),

            // Growth metrics
            _buildGrowthMetricsCard(),
            const SizedBox(height: 16),

            // User distribution
            _buildUserDistributionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendsCard() {
    if (_chartData == null) return const SizedBox();

    final days = List<String>.from(_chartData!['days'] ?? []);
    final signups = List<int>.from(_chartData!['signups'] ?? []);
    final mealPlans = List<int>.from(_chartData!['mealPlans'] ?? []);

    return Container(
      padding: const EdgeInsets.all(20),
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
              const Icon(Icons.trending_up, color: Color(0xFFCC1C14)),
              const SizedBox(width: 12),
              const Text(
                'Weekly Trends (Last 7 Days)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Simple bar chart representation
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(days.length, (index) {
                final maxSignups =
                    signups.isNotEmpty
                        ? signups.reduce((a, b) => a > b ? a : b)
                        : 1;
                final maxMealPlans =
                    mealPlans.isNotEmpty
                        ? mealPlans.reduce((a, b) => a > b ? a : b)
                        : 1;

                final signupHeight =
                    maxSignups > 0
                        ? (signups[index] / maxSignups * 120).clamp(10.0, 120.0)
                        : 10.0;
                final mealPlanHeight =
                    maxMealPlans > 0
                        ? (mealPlans[index] / maxMealPlans * 120).clamp(
                          10.0,
                          120.0,
                        )
                        : 10.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Values on top
                    Column(
                      children: [
                        Text(
                          signups[index].toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          mealPlans[index].toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Bars
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: signupHeight,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 12,
                          height: mealPlanHeight,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Day label
                    Text(days[index], style: const TextStyle(fontSize: 10)),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Signups', Colors.blue),
              const SizedBox(width: 20),
              _buildLegendItem('Meal Plans', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildGrowthMetricsCard() {
    if (_dashboardStats == null) return const SizedBox();

    final stats = _dashboardStats!;
    final totalUsers = stats['totalUsers'] ?? 0;
    final dailySignups = stats['dailySignups'] ?? 0;
    final totalMealPlans = stats['totalMealPlans'] ?? 0;
    final dailyMealPlans = stats['dailyMealPlans'] ?? 0;

    // Calculate growth percentages (mock data for demo)
    final userGrowth = totalUsers > 0 ? ((dailySignups / totalUsers) * 100) : 0;
    final mealPlanGrowth =
        totalMealPlans > 0 ? ((dailyMealPlans / totalMealPlans) * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(20),
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
              const Icon(Icons.analytics, color: Color(0xFFCC1C14)),
              const SizedBox(width: 12),
              const Text(
                'Growth Metrics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildGrowthMetricItem(
                  'User Growth',
                  '${userGrowth.toStringAsFixed(1)}%',
                  'Daily vs Total',
                  Colors.blue,
                  userGrowth > 0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGrowthMetricItem(
                  'Meal Plan Growth',
                  '${mealPlanGrowth.toStringAsFixed(1)}%',
                  'Daily vs Total',
                  Colors.orange,
                  mealPlanGrowth > 0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildGrowthMetricItem(
                  'Completion Rate',
                  '${stats['verifiedUsers'] != null && totalUsers > 0 ? ((stats['verifiedUsers'] / totalUsers) * 100).toStringAsFixed(1) : '0'}%',
                  'Verified Users',
                  Colors.green,
                  true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGrowthMetricItem(
                  'Active Users',
                  '${stats['activeUsers'] ?? 0}',
                  'Last 7 days',
                  Colors.purple,
                  true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthMetricItem(
    String title,
    String value,
    String subtitle,
    Color color,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDistributionCard() {
    if (_dashboardStats == null) return const SizedBox();

    final stats = _dashboardStats!;
    final totalUsers = stats['totalUsers'] ?? 0;
    final verifiedUsers = stats['verifiedUsers'] ?? 0;
    final completedProfiles = stats['completedProfiles'] ?? 0;
    final activeUsers = stats['activeUsers'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
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
              const Icon(Icons.pie_chart, color: Color(0xFFCC1C14)),
              const SizedBox(width: 12),
              const Text(
                'User Distribution',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildDistributionItem(
            'Email Verified',
            verifiedUsers,
            totalUsers,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildDistributionItem(
            'Profile Completed',
            completedProfiles,
            totalUsers,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildDistributionItem(
            'Active Users',
            activeUsers,
            totalUsers,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionItem(
    String label,
    int value,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (value / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '$value / $total (${(percentage * 100).toStringAsFixed(1)}%)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildActivityTab() {
    if (_recentActivity == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildActivitySection(
              'Recent Signups',
              _recentActivity!['recentSignups'] ?? [],
              Icons.person_add,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildActivitySection(
              'Recent Meal Plans',
              _recentActivity!['recentMealPlans'] ?? [],
              Icons.restaurant_menu,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildActivitySection(
              'Profile Completions',
              _recentActivity!['recentProfiles'] ?? [],
              Icons.person,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection(
    String title,
    List<dynamic> items,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(
                '$title (${items.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildActivityItem(item, color);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> item, Color color) {
    String title = '';
    String subtitle = '';
    String time = '';

    if (item.containsKey('name')) {
      // User signup or profile
      title = item['name'] ?? 'Unknown';
      subtitle = item['email'] ?? '';
      time = _formatRelativeTime(item['createdAt']);
    } else if (item.containsKey('user')) {
      // Meal plan
      title = item['user']?['name'] ?? 'Unknown User';
      subtitle = 'Generated meal plan • ${item['totalCalories']} calories';
      time = _formatRelativeTime(item['createdAt']);
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        radius: 20,
        child: Text(
          title.isNotEmpty ? title.substring(0, 1).toUpperCase() : '?',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Text(
        time,
        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
      ),
    );
  }

  Widget _buildReportsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildReportCard(
              'System Performance',
              'Overall system health and performance metrics',
              Icons.speed,
              Colors.blue,
              [
                'Database: Healthy',
                'API Response: Good',
                'User Satisfaction: High',
                'Uptime: 99.9%',
              ],
            ),
            const SizedBox(height: 16),
            _buildReportCard(
              'User Engagement',
              'How users are interacting with the platform',
              Icons.people,
              Colors.green,
              [
                'Daily Active Users: ${_dashboardStats?['activeUsers'] ?? 0}',
                'Meal Plans Generated: ${_dashboardStats?['totalMealPlans'] ?? 0}',
                'Profile Completions: ${_dashboardStats?['completedProfiles'] ?? 0}',
                'Average Session: 15 min',
              ],
            ),
            const SizedBox(height: 16),
            _buildReportCard(
              'Content Statistics',
              'Analysis of generated content and user data',
              Icons.analytics,
              Colors.orange,
              [
                'Total Users: ${_dashboardStats?['totalUsers'] ?? 0}',
                'Verified Accounts: ${_dashboardStats?['verifiedUsers'] ?? 0}',
                'Genetic Reports: ${_dashboardStats?['completedProfiles'] ?? 0}',
                'AI Interactions: High',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    String description,
    IconData icon,
    Color color,
    List<String> metrics,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...metrics
              .map(
                (metric) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(metric, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  String _formatRelativeTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    } catch (e) {
      return '';
    }
  }
}
