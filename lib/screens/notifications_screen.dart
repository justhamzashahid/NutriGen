import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock notification data - would come from backend in the future
  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Time for Breakfast!',
      'message':
          'Don\'t forget to have your nutritious breakfast. Start your day strong!',
      'time': '7:30 AM',
      'date': DateTime(2025, 1, 3),
      'icon': Icons.breakfast_dining,
    },
    {
      'title': 'You\'ve Reached Your Protein Goal!',
      'message':
          'Great job! You\'ve hit your daily protein target. Keep making progress!',
      'time': '1:00 PM',
      'date': DateTime(2025, 1, 3),
      'icon': Icons.fitness_center,
    },
    {
      'title': 'New Meal Suggestion for Dinner!',
      'message':
          'We\'ve added a new dinner option: Grilled Chicken with Veggies. Try it tonight!',
      'time': '5:00 PM',
      'date': DateTime(2025, 1, 3),
      'icon': Icons.dinner_dining,
    },
    {
      'title': 'Don\'t Forget Your Hydration Goal!',
      'message':
          'Don\'t forget to have your nutritious breakfast. Start your day strong!',
      'time': '3:00 PM',
      'date': DateTime(2025, 1, 3),
      'icon': Icons.water_drop,
    },
    {
      'title': 'Healthy Eating Tip of the Day',
      'message':
          'Adding leafy greens to your meals can boost your health! Try adding spinach or kale to your next meal.',
      'time': '8:00 AM',
      'date': DateTime(2025, 1, 3),
      'icon': Icons.tips_and_updates,
    },
    {
      'title': 'A New Nutritionist is Available',
      'message':
          'Dr. Emily is available to answer your questions about your meal plan.',
      'time': '10:00 AM',
      'date': DateTime(2025, 1, 2),
      'icon': Icons.person,
    },
  ];

  // Group notifications by date
  Map<DateTime, List<Map<String, dynamic>>> getGroupedNotifications() {
    Map<DateTime, List<Map<String, dynamic>>> grouped = {};

    for (var notification in notifications) {
      DateTime date = notification['date'];
      // Remove time component to group by day
      DateTime dateKey = DateTime(date.year, date.month, date.day);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }

      grouped[dateKey]!.add(notification);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedNotifications = getGroupedNotifications();
    final sortedDates =
        groupedNotifications.keys.toList()..sort(
          (a, b) => b.compareTo(a),
        ); // Sort dates descending (newest first)

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          groupedNotifications.isEmpty
              ? const Center(
                child: Text(
                  'No notifications yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final dateNotifications = groupedNotifications[date]!;

                  // Format the date header
                  String dateHeader;
                  final now = DateTime.now();
                  final yesterday = DateTime(now.year, now.month, now.day - 1);
                  final today = DateTime(now.year, now.month, now.day);

                  if (date == today) {
                    dateHeader = 'Today';
                  } else if (date == yesterday) {
                    dateHeader = 'Yesterday';
                  } else {
                    dateHeader = DateFormat('dd MMM, yyyy').format(date);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          top: 16,
                          bottom: 8,
                        ),
                        child: Text(
                          dateHeader,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ...dateNotifications
                          .map(
                            (notification) =>
                                _buildNotificationCard(notification),
                          )
                          .toList(),
                    ],
                  );
                },
              ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                notification['icon'] ?? Icons.notifications,
                color: const Color(0xFFCC1C14),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        notification['time'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
