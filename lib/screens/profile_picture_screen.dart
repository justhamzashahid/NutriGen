import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:nutrigen/screens/onboarding_complete_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nutrigen/services/profile_service.dart';

class ProfilePictureScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const ProfilePictureScreen({Key? key, required this.userProfile})
    : super(key: key);

  @override
  State<ProfilePictureScreen> createState() => _ProfilePictureScreenState();
}

class _ProfilePictureScreenState extends State<ProfilePictureScreen> {
  File? _imageFile;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
          });
        } else {
          // For mobile platforms
          setState(() {
            _imageFile = File(pickedFile.path);
          });
        }

        // Debug print to verify image was picked
        debugPrint("Image picked successfully: ${pickedFile.name}");
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitUserProfile() async {
    if (_imageFile == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a profile picture')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create an instance of ProfileService
      final profileService = ProfileService();

      // Call the service method to submit user profile data
      await profileService.submitUserProfile(
        userProfile: widget.userProfile,
        profilePicture: _imageFile ?? _webImage,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  OnboardingCompleteScreen(userProfile: widget.userProfile),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('Error during profile submission: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug print to verify userProfile data
    debugPrint(
      'User Profile data in ProfilePictureScreen: ${widget.userProfile}',
    );

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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              const Text(
                'Profile Picture',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Personalize your account with a profile picture on the nutrition app.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),

              // Step indicator
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Step 4 of 4',
                  style: TextStyle(
                    color: const Color(0xFFCC1C14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Profile picture upload section
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _showImageSourceSheet,
                    child: _getImageWidget(),
                  ),
                ),
              ),

              // Continue button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitUserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCC1C14),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isSubmitting
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
                          'Continue',
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

  Widget _getImageWidget() {
    // If we have a web image
    if (_webImage != null) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
          image: DecorationImage(
            image: MemoryImage(_webImage!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // If we have a mobile file image
    if (_imageFile != null) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
          image: DecorationImage(
            image: FileImage(_imageFile!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Default empty state
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.file_upload_outlined, color: Colors.grey[500], size: 40),
          const SizedBox(height: 8),
          Text(
            'Tap to upload',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
