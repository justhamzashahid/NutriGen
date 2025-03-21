import 'package:flutter/material.dart';
import 'package:nutrigen/screens/lifestyle_activities_screen.dart';

class GoalsPreferencesScreen extends StatefulWidget {
  final Map<String, dynamic> personalDetails;

  const GoalsPreferencesScreen({Key? key, required this.personalDetails})
    : super(key: key);

  @override
  State<GoalsPreferencesScreen> createState() => _GoalsPreferencesScreenState();
}

class _GoalsPreferencesScreenState extends State<GoalsPreferencesScreen> {
  final Set<String> _selectedGoals = {};
  final Set<String> _selectedDietPreferences = {};
  final Set<String> _selectedAllergies = {};

  // Options for goals, diet preferences, and allergies
  final List<Map<String, dynamic>> _goalOptions = [
    {'label': 'Maintain Fitness', 'icon': Icons.fitness_center},
    {'label': 'Improve Overall Health', 'icon': Icons.favorite},
    {'label': 'Manage Medical Condition', 'icon': Icons.medical_services},
    {'label': 'Weight Loss', 'icon': Icons.monitor_weight},
    {'label': 'Muscle Gain', 'icon': Icons.sports_gymnastics},
    {'label': 'Increase Energy Levels', 'icon': Icons.bolt},
    {'label': 'Better Sleep', 'icon': Icons.nightlight_round},
    {'label': 'Improve Mental Clarity', 'icon': Icons.psychology},
  ];

  final List<Map<String, dynamic>> _dietPreferenceOptions = [
    {'label': 'Vegetarian', 'icon': Icons.grass},
    {'label': 'Vegan', 'icon': Icons.spa},
    {'label': 'No Restrictions', 'icon': Icons.restaurant},
    {'label': 'Keto', 'icon': Icons.egg},
    {'label': 'Paleo', 'icon': Icons.eco},
    {'label': 'Mediterranean', 'icon': Icons.local_dining},
    {'label': 'Low Carb', 'icon': Icons.rice_bowl},
    {'label': 'Low Fat', 'icon': Icons.opacity},
  ];

  final List<Map<String, dynamic>> _allergyOptions = [
    {'label': 'Gluten', 'icon': Icons.bakery_dining},
    {'label': 'Shellfish', 'icon': Icons.set_meal},
    {'label': 'Dairy (Lactose)', 'icon': Icons.local_cafe},
    {
      'label': 'Nuts (e.g., Peanuts, Tree Nuts)',
      'icon': Icons.emoji_food_beverage,
    },
    {'label': 'Eggs', 'icon': Icons.egg_alt},
    {'label': 'Soy', 'icon': Icons.emoji_nature},
    {'label': 'Fish', 'icon': Icons.water},
    {'label': 'Wheat', 'icon': Icons.grass},
  ];

  void _proceedToNextStep() {
    if (_validateSelections()) {
      // In a real app, we would store all of these preferences
      final nutritionalPreferences = {
        'goals': _selectedGoals.toList(),
        'dietPreferences': _selectedDietPreferences.toList(),
        'allergies': _selectedAllergies.toList(),
      };

      // Combine with the personal details from the previous step
      final completeUserProfile = {
        ...widget.personalDetails,
        ...nutritionalPreferences,
      };

      // Print for debugging purposes
      debugPrint('User Profile: $completeUserProfile');

      // Navigate to the lifestyle and activities screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  LifestyleActivitiesScreen(userProfile: completeUserProfile),
        ),
      );
    }
  }

  bool _validateSelections() {
    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one goal')),
      );
      return false;
    }

    if (_selectedDietPreferences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one diet preference'),
        ),
      );
      return false;
    }

    return true;
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
                  'Goals & Preferences',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set your Nutritional goals, and your diet preferences.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),

                // Step indicator
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Step 2 of 4',
                    style: TextStyle(
                      color: const Color(0xFFCC1C14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Goals section
                const Text(
                  "What's Your Goal?",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _goalOptions.map((option) {
                        final isSelected = _selectedGoals.contains(
                          option['label'],
                        );
                        return _buildSelectionChip(
                          label: option['label'],
                          icon: option['icon'],
                          isSelected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedGoals.add(option['label']);
                              } else {
                                _selectedGoals.remove(option['label']);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 24),

                // Diet preferences section
                const Text(
                  "Your Diet Preferences?",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _dietPreferenceOptions.map((option) {
                        final isSelected = _selectedDietPreferences.contains(
                          option['label'],
                        );
                        return _buildSelectionChip(
                          label: option['label'],
                          icon: option['icon'],
                          isSelected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDietPreferences.add(option['label']);
                              } else {
                                _selectedDietPreferences.remove(
                                  option['label'],
                                );
                              }
                            });
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 24),

                // Allergies section
                const Text(
                  "Any Food Sensitivities or Allergies?",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _allergyOptions.map((option) {
                        final isSelected = _selectedAllergies.contains(
                          option['label'],
                        );
                        return _buildSelectionChip(
                          label: option['label'],
                          icon: option['icon'],
                          isSelected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAllergies.add(option['label']);
                              } else {
                                _selectedAllergies.remove(option['label']);
                              }
                            });
                          },
                        );
                      }).toList(),
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

  Widget _buildSelectionChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.black87,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.grey[100],
      selectedColor: const Color(0xFFCC1C14),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFFCC1C14) : Colors.grey.shade300,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}
