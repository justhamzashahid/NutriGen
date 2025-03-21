import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nutrigen/services/api_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  // Submit the complete user profile at the end of onboarding
  Future<Map<String, dynamic>> submitUserProfile({
    required Map<String, dynamic> userProfile,
    required dynamic profilePicture, // Can be File or Uint8List
  }) async {
    try {
      debugPrint('Raw userProfile: $userProfile');

      // Process profile picture to base64
      String? profilePictureBase64;
      if (profilePicture != null) {
        Uint8List bytes;
        if (profilePicture is File) {
          bytes = await profilePicture.readAsBytes();
        } else if (profilePicture is Uint8List) {
          bytes = profilePicture;
        } else {
          throw Exception("Unsupported profile picture format");
        }
        profilePictureBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      // Extract lifestyle data which is a nested map
      final lifestyle = userProfile['lifestyle'] as Map<String, dynamic>? ?? {};

      // Build the data payload
      final Map<String, dynamic> data = {
        // Personal details
        'age': int.tryParse(userProfile['age'].toString()) ?? 0,
        'gender': userProfile['gender'],
        'weight': double.tryParse(userProfile['weight'].toString()) ?? 0,
        'height': double.tryParse(userProfile['height'].toString()) ?? 0,
        'diabetesStage': userProfile['diabetesStage'],

        // Goals and preferences
        'healthGoals': userProfile['goals'] ?? [],
        'dietPreferences': userProfile['dietPreferences'] ?? [],
        'allergies': userProfile['allergies'] ?? [],

        // Lifestyle
        'lifestyleHabit': lifestyle['lifestyleHabit'],
        'sleepDuration': lifestyle['sleepDuration'],
        'stressLevel': lifestyle['stressLevel'],

        // Profile picture
        if (profilePictureBase64 != null)
          'profilePicture': profilePictureBase64,
      };

      // Process genetic report if available
      if (userProfile['reportFile'] != null) {
        final reportFile = userProfile['reportFile'];
        String reportFileName = reportFile.name;

        Uint8List reportBytes;
        if (kIsWeb) {
          // On web, we can directly access the bytes property
          reportBytes = reportFile.bytes!;
        } else if (reportFile is File) {
          reportBytes = await reportFile.readAsBytes();
        } else if (reportFile is PlatformFile) {
          final file = File(reportFile.path!);
          reportBytes = await file.readAsBytes();
        } else {
          throw Exception("Unsupported report file format");
        }

        String fileType = '';
        final extension = reportFileName.split('.').last.toLowerCase();

        if (extension == 'pdf') {
          fileType = 'application/pdf';
        } else if (extension == 'docx') {
          fileType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        } else if (extension == 'jpg' || extension == 'jpeg') {
          fileType = 'image/jpeg';
        } else if (extension == 'png') {
          fileType = 'image/png';
        }

        data['geneticReport'] =
            'data:$fileType;base64,${base64Encode(reportBytes)}';
        data['geneticReportName'] = reportFileName;
      }

      debugPrint('Sending profile data to backend: ${jsonEncode(data)}');
      return await _apiClient.post('/user/profile', data);
    } catch (e) {
      debugPrint('Error submitting user profile: $e');
      throw _handleError(e);
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      return await _apiClient.get('/user/profile');
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      throw _handleError(e);
    }
  }

  // Process genetic report separately
  Future<Map<String, dynamic>> processGeneticReport(PlatformFile file) async {
    try {
      String reportFileName = file.name;

      Uint8List reportBytes;
      if (kIsWeb) {
        // On web, we can directly access the bytes property
        reportBytes = file.bytes!;
      } else {
        // On mobile, we need to read the file from the path
        final fileObj = File(file.path!);
        reportBytes = await fileObj.readAsBytes();
      }

      String fileType = '';
      final extension = reportFileName.split('.').last.toLowerCase();

      if (extension == 'pdf') {
        fileType = 'application/pdf';
      } else if (extension == 'docx') {
        fileType =
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        fileType = 'image/jpeg';
      } else if (extension == 'png') {
        fileType = 'image/png';
      }

      final Map<String, dynamic> data = {
        'geneticReport': 'data:$fileType;base64,${base64Encode(reportBytes)}',
        'geneticReportName': reportFileName,
      };

      return await _apiClient.post(
        '/user/profile/process-genetic-report',
        data,
      );
    } catch (e) {
      debugPrint('Error processing genetic report: $e');
      throw _handleError(e);
    }
  }

  // Update account information (name, email, gender, profile picture)
  Future<Map<String, dynamic>> updateAccountInfo({
    String? name,
    String? email,
    String? gender,
    dynamic profilePicture, // Can be File or Uint8List
  }) async {
    try {
      // Process profile picture to base64 if provided
      String? profilePictureBase64;
      if (profilePicture != null) {
        Uint8List bytes;
        if (profilePicture is File) {
          bytes = await profilePicture.readAsBytes();
        } else if (profilePicture is Uint8List) {
          bytes = profilePicture;
        } else {
          throw Exception("Unsupported profile picture format");
        }
        profilePictureBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      // Build the data payload
      final Map<String, dynamic> data = {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (gender != null) 'gender': gender,
        if (profilePictureBase64 != null)
          'profilePicture': profilePictureBase64,
      };

      return await _apiClient.put('/user/profile/account', data);
    } catch (e) {
      debugPrint('Error updating account info: $e');
      throw _handleError(e);
    }
  }

  // Update personal details
  Future<Map<String, dynamic>> updatePersonalDetails({
    String? age,
    String? weight,
    String? height,
    String? diabetesStage,
    String? lifestyleHabit,
    String? sleepDuration,
    String? stressLevel,
    dynamic geneticReport, // Can be PlatformFile
  }) async {
    try {
      // Build the data payload
      final Map<String, dynamic> data = {
        if (age != null) 'age': age,
        if (weight != null) 'weight': weight,
        if (height != null) 'height': height,
        if (diabetesStage != null) 'diabetesStage': diabetesStage,
        if (lifestyleHabit != null) 'lifestyleHabit': lifestyleHabit,
        if (sleepDuration != null) 'sleepDuration': sleepDuration,
        if (stressLevel != null) 'stressLevel': stressLevel,
      };

      // Process genetic report to base64 if provided
      if (geneticReport != null) {
        String reportFileName = '';

        if (geneticReport is PlatformFile) {
          reportFileName = geneticReport.name;
        } else if (geneticReport is File) {
          reportFileName = geneticReport.path.split('/').last;
        }

        Uint8List bytes;
        if (kIsWeb && geneticReport is PlatformFile) {
          // On web, we can directly access the bytes property
          bytes = geneticReport.bytes!;
        } else if (geneticReport is File) {
          bytes = await geneticReport.readAsBytes();
        } else if (geneticReport is PlatformFile) {
          final file = File(geneticReport.path!);
          bytes = await file.readAsBytes();
        } else if (geneticReport is Uint8List) {
          bytes = geneticReport;
        } else {
          throw Exception("Unsupported genetic report format");
        }

        String fileType = '';
        if (reportFileName.isNotEmpty) {
          final extension = reportFileName.split('.').last.toLowerCase();

          if (extension == 'pdf') {
            fileType = 'application/pdf';
          } else if (extension == 'docx') {
            fileType =
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          } else if (extension == 'jpg' || extension == 'jpeg') {
            fileType = 'image/jpeg';
          } else if (extension == 'png') {
            fileType = 'image/png';
          }
        } else {
          fileType = 'application/pdf'; // Default to PDF if unknown
        }

        data['geneticReport'] = 'data:$fileType;base64,${base64Encode(bytes)}';
        data['geneticReportName'] = reportFileName;
      }

      return await _apiClient.put('/user/profile/personal-details', data);
    } catch (e) {
      debugPrint('Error updating personal details: $e');
      throw _handleError(e);
    }
  }

  // Update diet preferences
  Future<Map<String, dynamic>> updateDietPreferences({
    List<String>? healthGoals,
    List<String>? dietPreferences,
    List<String>? allergies,
  }) async {
    try {
      // Build the data payload
      final Map<String, dynamic> data = {
        if (healthGoals != null) 'healthGoals': healthGoals,
        if (dietPreferences != null) 'dietPreferences': dietPreferences,
        if (allergies != null) 'allergies': allergies,
      };

      return await _apiClient.put('/user/profile/diet-preferences', data);
    } catch (e) {
      debugPrint('Error updating diet preferences: $e');
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    return Exception('An unexpected error occurred: $error');
  }
}
