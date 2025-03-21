import 'package:flutter/material.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  // Notification settings
  bool _allowNotifications = true;

  // Meal reminder preferences
  bool _breakfastReminder = true;
  bool _lunchReminder = true;
  bool _dinnerReminder = true;

  // Health metrics preferences
  bool _calorieGoalAlerts = true;
  bool _proteinGoalAlerts = true;
  bool _hydrationReminders = true;

  // App updates preferences
  bool _newFeaturesUpdates = true;
  bool _nutritionTips = true;
  bool _weeklyReports = true;

  // Time settings
  String _breakfastTime = '07:30 AM';
  String _lunchTime = '12:30 PM';
  String _dinnerTime = '07:00 PM';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notification Preferences',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Master notification toggle
              _buildMasterToggle(),

              const SizedBox(height: 16),

              if (_allowNotifications) ...[
                // Meal reminder preferences
                _buildSectionHeader('Meal Reminders'),
                _buildSwitchTile(
                  title: 'Breakfast Reminder',
                  subtitle: 'Daily at $_breakfastTime',
                  value: _breakfastReminder,
                  onChanged: (value) {
                    setState(() => _breakfastReminder = value);
                    if (value) {
                      _showTimePickerDialog('Breakfast', _breakfastTime, (
                        newTime,
                      ) {
                        setState(() => _breakfastTime = newTime);
                      });
                    }
                  },
                  icon: Icons.breakfast_dining,
                  onTap: () {
                    if (_breakfastReminder) {
                      _showTimePickerDialog('Breakfast', _breakfastTime, (
                        newTime,
                      ) {
                        setState(() => _breakfastTime = newTime);
                      });
                    }
                  },
                ),

                _buildSwitchTile(
                  title: 'Lunch Reminder',
                  subtitle: 'Daily at $_lunchTime',
                  value: _lunchReminder,
                  onChanged: (value) {
                    setState(() => _lunchReminder = value);
                    if (value) {
                      _showTimePickerDialog('Lunch', _lunchTime, (newTime) {
                        setState(() => _lunchTime = newTime);
                      });
                    }
                  },
                  icon: Icons.lunch_dining,
                  onTap: () {
                    if (_lunchReminder) {
                      _showTimePickerDialog('Lunch', _lunchTime, (newTime) {
                        setState(() => _lunchTime = newTime);
                      });
                    }
                  },
                ),

                _buildSwitchTile(
                  title: 'Dinner Reminder',
                  subtitle: 'Daily at $_dinnerTime',
                  value: _dinnerReminder,
                  onChanged: (value) {
                    setState(() => _dinnerReminder = value);
                    if (value) {
                      _showTimePickerDialog('Dinner', _dinnerTime, (newTime) {
                        setState(() => _dinnerTime = newTime);
                      });
                    }
                  },
                  icon: Icons.dinner_dining,
                  onTap: () {
                    if (_dinnerReminder) {
                      _showTimePickerDialog('Dinner', _dinnerTime, (newTime) {
                        setState(() => _dinnerTime = newTime);
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Health metrics preferences
                _buildSectionHeader('Health Goal Alerts'),
                _buildSwitchTile(
                  title: 'Calorie Goal Alerts',
                  subtitle: 'Get notified about your daily calorie targets',
                  value: _calorieGoalAlerts,
                  onChanged:
                      (value) => setState(() => _calorieGoalAlerts = value),
                  icon: Icons.local_fire_department,
                ),

                _buildSwitchTile(
                  title: 'Protein Goal Alerts',
                  subtitle: 'Get notified about your protein intake',
                  value: _proteinGoalAlerts,
                  onChanged:
                      (value) => setState(() => _proteinGoalAlerts = value),
                  icon: Icons.fitness_center,
                ),

                _buildSwitchTile(
                  title: 'Hydration Reminders',
                  subtitle: 'Reminders to drink water throughout the day',
                  value: _hydrationReminders,
                  onChanged:
                      (value) => setState(() => _hydrationReminders = value),
                  icon: Icons.water_drop,
                ),

                const SizedBox(height: 16),

                // App updates preferences
                _buildSectionHeader('App Updates & Tips'),
                _buildSwitchTile(
                  title: 'New Features & Updates',
                  subtitle: 'Get notified about app updates and new features',
                  value: _newFeaturesUpdates,
                  onChanged:
                      (value) => setState(() => _newFeaturesUpdates = value),
                  icon: Icons.new_releases,
                ),

                _buildSwitchTile(
                  title: 'Nutrition Tips',
                  subtitle: 'Receive helpful nutrition tips and advice',
                  value: _nutritionTips,
                  onChanged: (value) => setState(() => _nutritionTips = value),
                  icon: Icons.tips_and_updates,
                ),

                _buildSwitchTile(
                  title: 'Weekly Reports',
                  subtitle: 'Weekly summary of your nutrition and health data',
                  value: _weeklyReports,
                  onChanged: (value) => setState(() => _weeklyReports = value),
                  icon: Icons.assessment,
                ),
              ],

              const SizedBox(height: 32),

              // Save button
              ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCC1C14),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save Preferences',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasterToggle() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _allowNotifications
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: const Color(0xFFCC1C14),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enable Notifications',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    _allowNotifications
                        ? 'Notifications are enabled'
                        : 'All notifications are currently disabled',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            Switch(
              value: _allowNotifications,
              onChanged: (value) {
                setState(() {
                  _allowNotifications = value;
                });
              },
              activeColor: const Color(0xFFCC1C14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFFCC1C14), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFFCC1C14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimePickerDialog(
    String mealType,
    String currentTime,
    Function(String) onTimeSelected,
  ) {
    // Parse the current time
    final timeParts = currentTime.split(' ');
    final hourMinute = timeParts[0].split(':');
    int hour = int.parse(hourMinute[0]);
    int minute = int.parse(hourMinute[1]);

    // Adjust for PM
    if (timeParts[1] == 'PM' && hour < 12) {
      hour += 12;
    }
    // Adjust for AM
    if (timeParts[1] == 'AM' && hour == 12) {
      hour = 0;
    }

    showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFCC1C14)),
          ),
          child: child!,
        );
      },
    ).then((selectedTime) {
      if (selectedTime != null) {
        // Convert to 12-hour format
        int hourIn12HourFormat = selectedTime.hourOfPeriod;
        if (hourIn12HourFormat == 0) {
          hourIn12HourFormat = 12;
        }

        final period = selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
        final formattedTime =
            '${hourIn12HourFormat.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} $period';

        onTimeSelected(formattedTime);
      }
    });
  }

  void _savePreferences() {
    // In a real app, you would save these preferences to local storage or a backend
    // For now, just show a confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification preferences saved'),
        backgroundColor: Color(0xFFCC1C14),
      ),
    );

    // Navigate back
    Navigator.of(context).pop();
  }
}
