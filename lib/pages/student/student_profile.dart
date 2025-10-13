import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/user_service.dart';
import '../../services/profile_image_service.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  Map<String, dynamic>? userProfile;
  Map<String, dynamic>? studentData;
  bool isLoading = true;
  bool isUploading = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Get user profile data
      final userResponse = await Supabase.instance.client
          .from('users')
          .select()
          .eq('user_id', userId)
          .single();

      // Get student data with all fields
      final studentResponse = await Supabase.instance.client
          .from('students')
          .select('first_name, last_name, student_code, course, year_level, education_level, strand')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        print('DEBUG: Profile loaded successfully');
        print('DEBUG: Profile picture value: ${userResponse['profile_picture'] != null ? "HAS IMAGE (${userResponse['profile_picture'].toString().length} chars)" : "NO IMAGE"}');
        
        setState(() {
          userProfile = userResponse;
          studentData = studentResponse;
          _emailController.text = userResponse['email'] ?? '';
          
          if (studentResponse != null) {
            _firstNameController.text = studentResponse['first_name'] ?? '';
            _lastNameController.text = studentResponse['last_name'] ?? '';
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    print('DEBUG: Starting image upload process');
    setState(() {
      isUploading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('DEBUG: No user ID found');
        return;
      }
      print('DEBUG: User ID: $userId');

      // Show image source selection dialog
      print('DEBUG: Showing image source dialog');
      final String? selectedImageBase64 = await ProfileImageService.showImageSourceDialog(context);
      
      if (selectedImageBase64 == null) {
        print('DEBUG: No image selected');
        setState(() {
          isUploading = false;
        });
        return;
      }
      
      print('DEBUG: Image selected, base64 length: ${selectedImageBase64.length}');

      // Update student profile image with base64 data
      print('DEBUG: Updating profile image in database');
      final success = await ProfileImageService.updateStudentProfileImage(
        selectedImageBase64,
        userId,
      );
      
      print('DEBUG: Database update success: $success');

      if (success) {
        // Reload the profile
        print('DEBUG: Reloading user profile');
        await _loadUserProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile picture')),
          );
        }
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      
      await UserService.updateStudentName(firstName, lastName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }

      await _loadUserProfile();
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentName = studentData != null 
        ? '${studentData!['first_name'] ?? ''} ${studentData!['last_name'] ?? ''}'.trim()
        : '';
    final studentCode = studentData?['student_code'] ?? '';
    final course = studentData?['course'] ?? '';
    final yearLevel = studentData?['year_level']?.toString() ?? '';
    final educationLevel = studentData?['education_level'] ?? '';
    final strand = studentData?['strand'] ?? '';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF5D5D72)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          "BreatheBetter",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
        actions: [
          const StudentNotificationButton(),
        ],
      ),
      drawer: const StudentDrawer(),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Welcome Section
                      Text(
                        'Student Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your profile information',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),

                      // Profile Picture Section
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: userProfile?['profile_picture'] != null && userProfile!['profile_picture'].toString().isNotEmpty
                                ? MemoryImage(base64Decode(userProfile!['profile_picture']))
                                : null,
                            child: userProfile?['profile_picture'] == null || userProfile!['profile_picture'].toString().isEmpty
                                ? Text(
                                    studentName.isNotEmpty
                                        ? studentName[0].toUpperCase()
                                        : 'S',
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF7C83FD),
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF7C83FD),
                                shape: BoxShape.circle,
                              ),
                              child: InkWell(
                                onTap: isUploading ? null : _uploadImage,
                                child: Icon(
                                  isUploading
                                      ? Icons.hourglass_empty
                                      : Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Student Code below profile picture
                      if (studentCode.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C83FD).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ID: $studentCode',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7C83FD),
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),

                      // Form Fields
                      _buildTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Please enter your first name'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Please enter your last name'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        enabled: false,
                      ),
                      const SizedBox(height: 16),

                      // Display student information (read-only)
                      if (course.isNotEmpty)
                        _buildInfoCard('Course', course),
                      if (yearLevel.isNotEmpty)
                        _buildInfoCard('Year Level', yearLevel),
                      if (educationLevel.isNotEmpty)
                        _buildInfoCard('Education Level', educationLevel.replaceAll('_', ' ').toUpperCase()),
                      if (strand.isNotEmpty)
                        _buildInfoCard('Strand', strand),

                      const SizedBox(height: 32),

                      // Update Profile Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C83FD),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Update Profile',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (route) => false,
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7C83FD),
                            side: const BorderSide(color: Color(0xFF7C83FD)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: enabled ? const Color(0xFF3A3A50) : Colors.grey[600],
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: const Color(0xFF3A3A50),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A3A50),
            ),
          ),
        ],
      ),
    );
  }
}
