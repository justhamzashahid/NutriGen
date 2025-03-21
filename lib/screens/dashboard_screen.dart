import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutrigen/screens/notifications_screen.dart';
import 'package:nutrigen/screens/personal_details_edit.dart';
import 'package:nutrigen/services/profile_service.dart';
import 'package:nutrigen/services/gemini_service.dart';
import 'package:nutrigen/widgets/gene_info_card.dart';
import 'package:nutrigen/screens/chatbot.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // This would come from user profile in the future
  String userName = 'User';
  String? geneMarker;
  bool _isLoading = true;
  final ProfileService _profileService = ProfileService();
  final GeminiService _geminiService = GeminiService();

  // Meal plan data
  Map<String, dynamic>? _mealPlanData;
  int targetCalories = 0;
  int caloriesEaten = 0;
  String? _userId;

  // Track which meals have been eaten
  Map<String, bool> _eatenMeals = {};

  Map<String, Map<String, dynamic>> macros = {
    'Protein': {'current': 0, 'target': 0},
    'Carbs': {'current': 0, 'target': 0},
    'Fat': {'current': 0, 'target': 0},
  };

  // Meal recommendations from meal plan
  List<Map<String, dynamic>> breakfastRecommendations = [];
  List<Map<String, dynamic>> lunchRecommendations = [];
  List<Map<String, dynamic>> dinnerRecommendations = [];
  List<Map<String, dynamic>> snacksRecommendations =
      []; // Added snacks recommendations

  @override
  void initState() {
    super.initState();
    _getUserId();
    _loadUserProfile();
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });
    debugPrint('User ID loaded: $_userId');
    _loadMealPlanData();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _profileService.getUserProfile();

      if (response['success'] == true) {
        final data = response['data'];

        setState(() {
          userName = data['name'] ?? 'User';
          geneMarker = data['geneMarker'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMealPlanData() async {
    try {
      if (_userId == null) return;

      // Load meal plan data from backend
      setState(() {
        _isLoading = true;
      });

      final mealPlanData = await _geminiService.getTodaysMealPlan(_userId!);

      if (mealPlanData != null) {
        // Calculate total calories for target
        final totalCalories = mealPlanData['totalCalories'] ?? 0;
        final totalProtein = mealPlanData['totalProtein'] ?? 0;
        final totalCarbs = mealPlanData['totalCarbs'] ?? 0;
        final totalFat = mealPlanData['totalFat'] ?? 0;

        // Update state with the meal plan data
        setState(() {
          _mealPlanData = mealPlanData;
          targetCalories = totalCalories;

          // Get eaten status from the meal plan data in the backend
          _eatenMeals = {
            'breakfast': mealPlanData['breakfast']?['eaten'] ?? false,
            'lunch': mealPlanData['lunch']?['eaten'] ?? false,
            'dinner': mealPlanData['dinner']?['eaten'] ?? false,
            'snacks': mealPlanData['snacks']?['eaten'] ?? false,
          };

          // Calculate calories eaten based on the eaten status
          caloriesEaten = _calculateCaloriesEaten();

          // Update macros
          macros = {
            'Protein': {
              'current': _calculateMacroEaten('protein'),
              'target': totalProtein,
            },
            'Carbs': {
              'current': _calculateMacroEaten('carbs'),
              'target': totalCarbs,
            },
            'Fat': {'current': _calculateMacroEaten('fat'), 'target': totalFat},
          };

          // Create meal recommendations
          if (mealPlanData['breakfast'] != null) {
            breakfastRecommendations = [
              {
                'name': mealPlanData['breakfast']['title'],
                'description':
                    'Personalized breakfast based on your genetic profile',
                'calories': mealPlanData['breakfast']['calories'],
                'protein': mealPlanData['breakfast']['protein'],
                'carbs': mealPlanData['breakfast']['carbs'],
                'fat': mealPlanData['breakfast']['fat'],
                'selected': true,
                'icon': Icons.breakfast_dining,
              },
            ];
          }

          if (mealPlanData['lunch'] != null) {
            lunchRecommendations = [
              {
                'name': mealPlanData['lunch']['title'],
                'description':
                    'Personalized lunch based on your genetic profile',
                'calories': mealPlanData['lunch']['calories'],
                'protein': mealPlanData['lunch']['protein'],
                'carbs': mealPlanData['lunch']['carbs'],
                'fat': mealPlanData['lunch']['fat'],
                'selected': true,
                'icon': Icons.lunch_dining,
              },
            ];
          }

          if (mealPlanData['dinner'] != null) {
            dinnerRecommendations = [
              {
                'name': mealPlanData['dinner']['title'],
                'description':
                    'Personalized dinner based on your genetic profile',
                'calories': mealPlanData['dinner']['calories'],
                'protein': mealPlanData['dinner']['protein'],
                'carbs': mealPlanData['dinner']['carbs'],
                'fat': mealPlanData['dinner']['fat'],
                'selected': true,
                'icon': Icons.dinner_dining,
              },
            ];
          }

          // Add snacks if they exist
          if (mealPlanData['snacks'] != null) {
            snacksRecommendations = [
              {
                'name': mealPlanData['snacks']['title'],
                'description':
                    'Personalized snacks based on your genetic profile',
                'calories': mealPlanData['snacks']['calories'],
                'protein': mealPlanData['snacks']['protein'],
                'carbs': mealPlanData['snacks']['carbs'],
                'fat': mealPlanData['snacks']['fat'],
                'selected': true,
                'icon': Icons.icecream,
              },
            ];
          } else {
            snacksRecommendations = [];
          }

          _isLoading = false;
        });
      } else {
        // No meal plan for today, use default values
        setState(() {
          _mealPlanData = null;
          targetCalories = 2000; // Default value
          caloriesEaten = 0;

          macros = {
            'Protein': {'current': 0, 'target': 100},
            'Carbs': {'current': 0, 'target': 250},
            'Fat': {'current': 0, 'target': 70},
          };

          // Clear meal recommendations
          breakfastRecommendations = [];
          lunchRecommendations = [];
          dinnerRecommendations = [];
          snacksRecommendations = [];

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading meal plan data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Calculate calories eaten based on the meal plan and eaten status
  int _calculateCaloriesEaten() {
    if (_mealPlanData == null) return 0;

    int totalCaloriesEaten = 0;

    // Check breakfast
    if (_eatenMeals['breakfast'] == true &&
        _mealPlanData!['breakfast'] != null) {
      totalCaloriesEaten += _mealPlanData!['breakfast']['calories'] as int;
    }

    // Check lunch
    if (_eatenMeals['lunch'] == true && _mealPlanData!['lunch'] != null) {
      totalCaloriesEaten += _mealPlanData!['lunch']['calories'] as int;
    }

    // Check dinner
    if (_eatenMeals['dinner'] == true && _mealPlanData!['dinner'] != null) {
      totalCaloriesEaten += _mealPlanData!['dinner']['calories'] as int;
    }

    // Check snacks
    if (_eatenMeals['snacks'] == true && _mealPlanData!['snacks'] != null) {
      totalCaloriesEaten += _mealPlanData!['snacks']['calories'] as int;
    }

    // Include additional foods if available
    if (_mealPlanData!.containsKey('additionalFoods') &&
        _mealPlanData!['additionalFoods'] != null &&
        _mealPlanData!['additionalFoods'].isNotEmpty) {
      for (var food in _mealPlanData!['additionalFoods']) {
        totalCaloriesEaten += food['calories'] as int;
      }
    }

    return totalCaloriesEaten;
  }

  // Calculate specific macro eaten (protein, carbs, fat)
  int _calculateMacroEaten(String macroType) {
    if (_mealPlanData == null) return 0;

    int totalMacroEaten = 0;

    // Check breakfast
    if (_eatenMeals['breakfast'] == true &&
        _mealPlanData!['breakfast'] != null) {
      totalMacroEaten += _mealPlanData!['breakfast'][macroType] as int;
    }

    // Check lunch
    if (_eatenMeals['lunch'] == true && _mealPlanData!['lunch'] != null) {
      totalMacroEaten += _mealPlanData!['lunch'][macroType] as int;
    }

    // Check dinner
    if (_eatenMeals['dinner'] == true && _mealPlanData!['dinner'] != null) {
      totalMacroEaten += _mealPlanData!['dinner'][macroType] as int;
    }

    // Check snacks
    if (_eatenMeals['snacks'] == true && _mealPlanData!['snacks'] != null) {
      totalMacroEaten += _mealPlanData!['snacks'][macroType] as int;
    }

    // Include additional foods if available
    if (_mealPlanData!.containsKey('additionalFoods') &&
        _mealPlanData!['additionalFoods'] != null &&
        _mealPlanData!['additionalFoods'].isNotEmpty) {
      for (var food in _mealPlanData!['additionalFoods']) {
        totalMacroEaten += food[macroType] as int;
      }
    }

    return totalMacroEaten;
  }

  // Check if all meals are eaten and show congratulation
  void _checkAllMealsEaten() {
    if (_mealPlanData == null) return;

    bool allEaten = true;

    // Check breakfast
    if (_mealPlanData!.containsKey('breakfast') &&
        _mealPlanData!['breakfast'] != null) {
      allEaten = allEaten && (_eatenMeals['breakfast'] ?? false);
    }

    // Check lunch
    if (_mealPlanData!.containsKey('lunch') &&
        _mealPlanData!['lunch'] != null) {
      allEaten = allEaten && (_eatenMeals['lunch'] ?? false);
    }

    // Check dinner
    if (_mealPlanData!.containsKey('dinner') &&
        _mealPlanData!['dinner'] != null) {
      allEaten = allEaten && (_eatenMeals['dinner'] ?? false);
    }

    // Check snacks
    if (_mealPlanData!.containsKey('snacks') &&
        _mealPlanData!['snacks'] != null) {
      allEaten = allEaten && (_eatenMeals['snacks'] ?? false);
    }

    if (allEaten) {
      _showCongratulationsDialog();
    }
  }

  // Show congratulations dialog
  void _showCongratulationsDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.celebration, color: Colors.green),
                SizedBox(width: 8),
                Text('Congratulations!'),
              ],
            ),
            content: Text(
              'You have completed your target calories for today! Try to maintain this routine and avoid additional snacking for best results.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );
  }

  // Toggle meal eaten status and update backend
  void _toggleMealEaten(String mealType) async {
    // Toggle the status locally for immediate UI update
    setState(() {
      _eatenMeals[mealType] = !(_eatenMeals[mealType] ?? false);
    });

    // Update the calories eaten amount
    caloriesEaten = _calculateCaloriesEaten();

    // Update the macros
    setState(() {
      macros = {
        'Protein': {
          'current': _calculateMacroEaten('protein'),
          'target': macros['Protein']!['target'],
        },
        'Carbs': {
          'current': _calculateMacroEaten('carbs'),
          'target': macros['Carbs']!['target'],
        },
        'Fat': {
          'current': _calculateMacroEaten('fat'),
          'target': macros['Fat']!['target'],
        },
      };
    });

    // Update the backend
    try {
      final result = await _geminiService.updateMealEatenStatus(
        mealType,
        _eatenMeals[mealType] ?? false,
      );

      if (result) {
        // Check if all meals have been eaten and show congratulation message
        _checkAllMealsEaten();
      } else {
        // If update failed, revert the change locally
        setState(() {
          _eatenMeals[mealType] = !(_eatenMeals[mealType] ?? false);
          caloriesEaten = _calculateCaloriesEaten();

          // Update macros as well
          macros = {
            'Protein': {
              'current': _calculateMacroEaten('protein'),
              'target': macros['Protein']!['target'],
            },
            'Carbs': {
              'current': _calculateMacroEaten('carbs'),
              'target': macros['Carbs']!['target'],
            },
            'Fat': {
              'current': _calculateMacroEaten('fat'),
              'target': macros['Fat']!['target'],
            },
          };
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update meal status')),
        );
      }
    } catch (e) {
      debugPrint('Error updating meal eaten status: $e');
      // Revert the change locally if there's an error
      setState(() {
        _eatenMeals[mealType] = !(_eatenMeals[mealType] ?? false);
        caloriesEaten = _calculateCaloriesEaten();

        // Update macros as well
        macros = {
          'Protein': {
            'current': _calculateMacroEaten('protein'),
            'target': macros['Protein']!['target'],
          },
          'Carbs': {
            'current': _calculateMacroEaten('carbs'),
            'target': macros['Carbs']!['target'],
          },
          'Fat': {
            'current': _calculateMacroEaten('fat'),
            'target': macros['Fat']!['target'],
          },
        };
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating meal status: $e')));
    }
  }

  void _navigateToPersonalDetails() async {
    try {
      final response = await _profileService.getUserProfile();

      if (response['success'] == true) {
        if (!mounted) return;

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    PersonalDetailsEditScreen(userProfile: response['data']),
          ),
        );

        if (result == true) {
          _loadUserProfile();
        }
      }
    } catch (e) {
      debugPrint('Error navigating to personal details: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFCC1C14)),
              )
              : SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with welcome message and notification
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.notifications_none),
                              onPressed: () {
                                // Navigate to notifications screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const NotificationsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Genetic information card
                        GeneInfoCard(
                          geneMarker: geneMarker,
                          onUploadReport: _navigateToPersonalDetails,
                        ),

                        const SizedBox(height: 24),

                        // Stats section header with date selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Stats Today',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFCC1C14),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Color(0xFFCC1C14),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM d').format(DateTime.now()),
                                    style: const TextStyle(
                                      color: Color(0xFFCC1C14),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // No meal plan message or stats
                        _mealPlanData == null
                            ? _buildNoMealPlanMessage()
                            : Column(
                              children: [
                                // Calories progress circular indicator
                                Center(
                                  child: Column(
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          SizedBox(
                                            width: 180,
                                            height: 180,
                                            child: CircularProgressIndicator(
                                              value:
                                                  targetCalories > 0
                                                      ? caloriesEaten /
                                                          targetCalories
                                                      : 0,
                                              strokeWidth: 12,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(Color(0xFFCC1C14)),
                                            ),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'calories',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.indigo,
                                                ),
                                              ),
                                              Text(
                                                '$targetCalories',
                                                style: const TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.indigo,
                                                ),
                                              ),
                                              const Text(
                                                'Your target calories\nfor today',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Macros indicators
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    for (final entry in macros.entries)
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry.key,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value:
                                                      entry.value['target'] > 0
                                                          ? entry.value['current'] /
                                                              entry
                                                                  .value['target']
                                                          : 0,
                                                  backgroundColor:
                                                      Colors.grey.shade200,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(
                                                        entry.key == 'Protein'
                                                            ? const Color(
                                                              0xFFCC1C14,
                                                            )
                                                            : entry.key ==
                                                                'Carbs'
                                                            ? Colors.amber
                                                            : Colors.green,
                                                      ),
                                                  minHeight: 6,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "${entry.value['current']}/${entry.value['target']} g",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Calories eaten summary
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStatBox(
                                      icon: Icons.local_fire_department,
                                      iconColor: Colors.red,
                                      title: '$caloriesEaten Kcal',
                                      subtitle: 'Eaten',
                                      backgroundColor: Colors.red.shade50,
                                    ),
                                    const SizedBox(width: 16),
                                    // Hidden box for layout balance
                                    Opacity(
                                      opacity: 0,
                                      child: _buildStatBox(
                                        icon: Icons.restaurant_menu,
                                        iconColor: Colors.green,
                                        title: '',
                                        subtitle: '',
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                        const SizedBox(height: 24),

                        // Meal recommendations section
                        const Text(
                          'Today\'s Meal Plan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // No meal plan message or meal plan sections
                        _mealPlanData == null
                            ? const Text(
                              'No meal plan for today. Go to the chatbot to generate one!',
                            )
                            : Column(
                              children: [
                                if (breakfastRecommendations.isNotEmpty)
                                  _buildMealRecommendationSection(
                                    'Breakfast',
                                    breakfastRecommendations,
                                  ),
                                if (lunchRecommendations.isNotEmpty)
                                  _buildMealRecommendationSection(
                                    'Lunch',
                                    lunchRecommendations,
                                  ),
                                if (dinnerRecommendations.isNotEmpty)
                                  _buildMealRecommendationSection(
                                    'Dinner',
                                    dinnerRecommendations,
                                  ),
                                if (snacksRecommendations.isNotEmpty)
                                  _buildMealRecommendationSection(
                                    'Snacks',
                                    snacksRecommendations,
                                  ),

                                // Additional Foods Section
                                if (_mealPlanData!.containsKey(
                                      'additionalFoods',
                                    ) &&
                                    _mealPlanData!['additionalFoods'] != null &&
                                    _mealPlanData!['additionalFoods']
                                        .isNotEmpty)
                                  _buildAdditionalFoodsSection(),
                              ],
                            ),

                        const SizedBox(
                          height: 80,
                        ), // Space for bottom navigation
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildAdditionalFoodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.fastfood, size: 18, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              const Text(
                'Additional Foods',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ...((_mealPlanData!['additionalFoods'] as List)
            .map(
              (food) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade100),
                ),
                child: Row(
                  children: [
                    Text(
                      food['title'],
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      '${food['calories']} kcal',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList()),
      ],
    );
  }

  Widget _buildNoMealPlanMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.restaurant_menu, color: Color(0xFFCC1C14), size: 48),
          const SizedBox(height: 16),
          const Text(
            'No Meal Plan Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFCC1C14),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You don\'t have a meal plan for today yet. Visit the AI Chatbot to generate a personalized meal plan based on your genetic profile and preferences.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to chatbot screen (index 1 in bottom nav)
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const AIChatbotScreen(),
                ),
              );
            },
            icon: const Icon(Icons.chat),
            label: const Text('Go to AI Chatbot'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCC1C14),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color backgroundColor,
    bool expanded = true, // Add this parameter
  }) {
    Widget container = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min, // Add this to prevent layout issues
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );

    return expanded ? Expanded(child: container) : container;
  }

  Widget _buildMealRecommendationSection(
    String title,
    List<Map<String, dynamic>> meals,
  ) {
    String mealType = title.toLowerCase(); // "Breakfast" → "breakfast"

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...meals.map((meal) => _buildMealCard(meal, mealType)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, String mealType) {
    bool isEaten = _eatenMeals[mealType] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
                meal['icon'] ?? Icons.restaurant,
                color: const Color(0xFFCC1C14),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    meal['description'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '${meal['calories']} kcal',
                  style: const TextStyle(
                    color: Color(0xFFCC1C14),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                // Add eaten button
                ElevatedButton.icon(
                  onPressed: () => _toggleMealEaten(mealType),
                  icon: Icon(
                    isEaten ? Icons.check_circle : Icons.circle_outlined,
                  ),
                  label: Text(isEaten ? 'Eaten' : 'Mark eaten'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isEaten ? Colors.green : Colors.grey.shade200,
                    foregroundColor: isEaten ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(80, 30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
