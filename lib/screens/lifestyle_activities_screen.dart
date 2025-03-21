import 'package:flutter/material.dart';
import 'package:nutrigen/screens/profile_picture_screen.dart';

class LifestyleActivitiesScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const LifestyleActivitiesScreen({Key? key, required this.userProfile})
    : super(key: key);

  @override
  State<LifestyleActivitiesScreen> createState() =>
      _LifestyleActivitiesScreenState();
}

class _LifestyleActivitiesScreenState extends State<LifestyleActivitiesScreen> {
  String? _selectedLifestyleHabit;
  String? _selectedSleepDuration;
  String? _selectedStressLevel;

  // Options for lifestyle habits, sleep duration, and stress level
  final List<String> _lifestyleOptions = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Extremely Active',
  ];

  final List<String> _sleepDurationOptions = [
    'Less than 5 hours',
    '5-7 hours',
    '7-9 hours',
    'More than 9 hours',
  ];

  final List<String> _stressLevelOptions = ['Low', 'Moderate', 'High'];

  bool _validateSelections() {
    if (_selectedLifestyleHabit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your lifestyle habit')),
      );
      return false;
    }

    if (_selectedSleepDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your sleep duration')),
      );
      return false;
    }

    if (_selectedStressLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your stress level')),
      );
      return false;
    }

    return true;
  }

  void _proceedToNextStep() {
    if (_validateSelections()) {
      // Add the lifestyle data to the user profile
      final lifestyleData = {
        'lifestyleHabit': _selectedLifestyleHabit,
        'sleepDuration': _selectedSleepDuration,
        'stressLevel': _selectedStressLevel,
      };

      // Combine with the existing user profile data
      final updatedUserProfile = {
        ...widget.userProfile,
        'lifestyle': lifestyleData,
      };

      // Navigate to the profile picture screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  ProfilePictureScreen(userProfile: updatedUserProfile),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                const Text(
                  'Lifestyle & Activities',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'How active you are and how you prefer to eat, so we can match your nutrition plan.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),

                // Step indicator
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Step 3 of 4',
                    style: TextStyle(
                      color: const Color(0xFFCC1C14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Lifestyle Habits Dropdown
                const Text(
                  'Your Lifestyle Habits',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedLifestyleHabit,
                    hint: const Text('e.g. Sedentary'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items:
                        _lifestyleOptions.map((String habit) {
                          return DropdownMenuItem<String>(
                            value: habit,
                            child: Text(habit),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLifestyleHabit = newValue;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Sleep Duration Dropdown
                const Text(
                  'How many hours do you sleep?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedSleepDuration,
                    hint: const Text('e.g. 7-9 hours'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items:
                        _sleepDurationOptions.map((String duration) {
                          return DropdownMenuItem<String>(
                            value: duration,
                            child: Text(duration),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSleepDuration = newValue;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Stress Level Dropdown
                const Text(
                  'How would you rate your stress level?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedStressLevel,
                    hint: const Text('e.g. Moderate'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items:
                        _stressLevelOptions.map((String level) {
                          return DropdownMenuItem<String>(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedStressLevel = newValue;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Next button
                ElevatedButton(
                  onPressed: _proceedToNextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCC1C14),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
