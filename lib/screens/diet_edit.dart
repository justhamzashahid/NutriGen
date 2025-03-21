import 'package:flutter/material.dart';
import 'package:nutrigen/services/profile_service.dart';

class DietEditScreen extends StatefulWidget {
  final List<dynamic>? healthGoals;
  final List<dynamic>? dietPreferences;
  final List<dynamic>? allergies;

  const DietEditScreen({
    Key? key,
    this.healthGoals,
    this.dietPreferences,
    this.allergies,
  }) : super(key: key);

  @override
  State<DietEditScreen> createState() => _DietEditScreenState();
}

class _DietEditScreenState extends State<DietEditScreen> {
  // Selected goals
  final Set<String> _selectedGoals = {};

  // Selected diet preferences
  final Set<String> _selectedDietPreferences = {};

  // Selected allergies
  final Set<String> _selectedAllergies = {};

  bool _isLoading = false;
  final ProfileService _profileService = ProfileService();

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

  @override
  void initState() {
    super.initState();

    // Initialize selected goals from user data
    if (widget.healthGoals != null) {
      for (var goal in widget.healthGoals!) {
        _selectedGoals.add(goal.toString());
      }
    }

    // Initialize selected diet preferences from user data
    if (widget.dietPreferences != null) {
      for (var pref in widget.dietPreferences!) {
        _selectedDietPreferences.add(pref.toString());
      }
    }

    // Initialize selected allergies from user data
    if (widget.allergies != null) {
      for (var allergy in widget.allergies!) {
        _selectedAllergies.add(allergy.toString());
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _profileService.updateDietPreferences(
        healthGoals: _selectedGoals.toList(),
        dietPreferences: _selectedDietPreferences.toList(),
        allergies: _selectedAllergies.toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diet preferences saved successfully')),
      );

      // Return true to indicate that changes were made
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error saving diet preferences: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Diet Preferences',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goals section
              const Text(
                "What's Your Goal?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
                              _selectedDietPreferences.remove(option['label']);
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
              const SizedBox(height: 16),
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

              // Save button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCC1C14),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ],
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
