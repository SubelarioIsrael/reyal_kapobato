import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery and convert to base64
  static Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        final File file = File(image.path);
        final Uint8List imageBytes = await file.readAsBytes();
        final String base64String = base64Encode(imageBytes);
        return base64String;
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      rethrow;
    }
  }

  /// Pick image from camera and convert to base64
  static Future<String?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        final File file = File(image.path);
        final Uint8List imageBytes = await file.readAsBytes();
        final String base64String = base64Encode(imageBytes);
        return base64String;
      }
      return null;
    } catch (e) {
      print('Error taking photo: $e');
      rethrow;
    }
  }



  /// Show image source selection dialog
  static Future<String?> showImageSourceDialog(context) async {
    String? selectedImageBase64;
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  selectedImageBase64 = await pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  selectedImageBase64 = await pickImageFromCamera();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    
    return selectedImageBase64;
  }

  /// Update profile image for counselor (stores base64 data directly in database)
  static Future<bool> updateCounselorProfileImage(String base64Image, String userId) async {
    try {
      // Update user profile with base64 image data
      await _supabase
          .from('users')
          .update({'profile_picture': base64Image})
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error updating counselor profile image: $e');
      return false;
    }
  }

  /// Update profile image for student (stores base64 data directly in database)
  static Future<bool> updateStudentProfileImage(String base64Image, String userId) async {
    try {
      // Update user profile with base64 image data
      await _supabase
          .from('users')
          .update({'profile_picture': base64Image})
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error updating student profile image: $e');
      return false;
    }
  }

  /// Get current user's profile image URL
  static Future<String?> getCurrentUserProfileImage() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Check if user is a counselor
      final counselorResult = await _supabase
          .from('counselors')
          .select('profile_picture')
          .eq('user_id', user.id)
          .maybeSingle();

      if (counselorResult != null) {
        return counselorResult['profile_picture'] as String?;
      }

      // Check users table for students
      final userResult = await _supabase
          .from('users')
          .select('profile_picture')
          .eq('user_id', user.id)
          .maybeSingle();

      return userResult?['profile_picture'] as String?;
    } catch (e) {
      print('Error getting current user profile image: $e');
      return null;
    }
  }
}