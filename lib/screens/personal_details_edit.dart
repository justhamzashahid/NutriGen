import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:nutrigen/services/profile_service.dart';
import 'package:nutrigen/widgets/genetic_report_widget.dart';
import 'dart:io';

class PersonalDetailsEditScreen extends StatefulWidget {
  final Map<String, dynamic>? userProfile;

  const PersonalDetailsEditScreen({Key? key, this.userProfile})
    : super(key: key);

  @override
  State<PersonalDetailsEditScreen> createState() =>
      _PersonalDetailsEditScreenState();
}

class _PersonalDetailsEditScreenState extends State<PersonalDetailsEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;

  late String? _selectedGender;
  late String? _selectedDiabetesStage;
  late String? _selectedLifestyleHabit;
  late String? _selectedSleepDuration;
  late String? _selectedStressLevel;

  String? _fileName;
  String? _geneMarker;
  PlatformFile? _pickedFile;
  bool _isProcessingReport = false;
  bool _isLoading = false;
  final ProfileService _profileService = ProfileService();

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  final List<String> _diabetesStageOptions = [
    'Non-diabetic',
    'Pre-diabetic',
    'Type 1',
    'Type 2',
    'Gestational',
    'Not sure',
  ];

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

  @override
  void initState() {
    super.initState();
    // Initialize controllers with user data if available
    _ageController = TextEditingController(
      text:
          widget.userProfile != null
              ? widget.userProfile!['age']?.toString() ?? ''
              : '',
    );
    _weightController = TextEditingController(
      text:
          widget.userProfile != null
              ? widget.userProfile!['weight']?.toString() ?? ''
              : '',
    );
    _heightController = TextEditingController(
      text:
          widget.userProfile != null
              ? widget.userProfile!['height']?.toString() ?? ''
              : '',
    );

    // Initialize dropdowns with user data if available
    _selectedGender =
        widget.userProfile != null ? widget.userProfile!['gender'] : null;
    _selectedDiabetesStage =
        widget.userProfile != null
            ? widget.userProfile!['diabetesStage']
            : null;
    _selectedLifestyleHabit =
        widget.userProfile != null
            ? widget.userProfile!['lifestyleHabit']
            : null;
    _selectedSleepDuration =
        widget.userProfile != null
            ? widget.userProfile!['sleepDuration']
            : null;
    _selectedStressLevel =
        widget.userProfile != null ? widget.userProfile!['stressLevel'] : null;

    // Initialize genetic report file and gene marker if exists
    _fileName =
        widget.userProfile != null
            ? widget.userProfile!['geneticReportFile']
            : null;
    _geneMarker =
        widget.userProfile != null ? widget.userProfile!['geneMarker'] : null;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _onReportPicked(PlatformFile file) {
    setState(() {
      _pickedFile = file;
      _isProcessingReport = true;
    });
  }

  void _onGeneMarkerUpdated(String? geneMarker) {
    setState(() {
      _geneMarker = geneMarker;
      _isProcessingReport = false;
    });
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Check dropdown selections
    if (_selectedDiabetesStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your diabetes stage')),
      );
      return false;
    }

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

  Future<void> _saveChanges() async {
    if (_validateForm()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Call the API to update personal details
        await _profileService.updatePersonalDetails(
          age: _ageController.text,
          weight: _weightController.text,
          height: _heightController.text,
          diabetesStage: _selectedDiabetesStage,
          lifestyleHabit: _selectedLifestyleHabit,
          sleepDuration: _selectedSleepDuration,
          stressLevel: _selectedStressLevel,
          geneticReport: _pickedFile,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal details saved successfully')),
        );

        // Return true to indicate that changes were made
        Navigator.pop(context, true);
      } catch (e) {
        debugPrint('Error saving personal details: $e');

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));

        setState(() {
          _isLoading = false;
        });
      }
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
          'Personal Details',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap:
            () =>
                FocusScope.of(
                  context,
                ).unfocus(), // Dismiss keyboard when tapping outside
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Age Field
                const Text(
                  'Your Age',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your age';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 120) {
                      return 'Please enter a valid age';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Gender Dropdown
                const Text(
                  'Your Gender',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items:
                        _genderOptions.map((String gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Weight Input
                const Text(
                  'Your Weight (kg)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your weight';
                    }
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0 || weight > 300) {
                      return 'Please enter a valid weight';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Height input
                const Text(
                  'Your Height (cm)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your height';
                    }
                    final height = double.tryParse(value);
                    if (height == null || height <= 0 || height > 300) {
                      return 'Please enter a valid height';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Diabetes stage dropdown
                const Text(
                  "What's Your Diabetes Stage?",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedDiabetesStage,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items:
                        _diabetesStageOptions.map((String stage) {
                          return DropdownMenuItem<String>(
                            value: stage,
                            child: Text(stage),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDiabetesStage = newValue;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Genetic Report Upload
                GeneticReportWidget(
                  geneticReportFile: _fileName,
                  geneMarker: _geneMarker,
                  onReportPicked: _onReportPicked,
                  onGeneMarkerUpdated: _onGeneMarkerUpdated,
                  isProcessing: _isProcessingReport,
                ),
                const SizedBox(height: 24),

                // Lifestyle section
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
                const SizedBox(height: 16),

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
                const SizedBox(height: 16),

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

                // Save button
                ElevatedButton(
                  onPressed:
                      (_isLoading || _isProcessingReport) ? null : _saveChanges,
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
