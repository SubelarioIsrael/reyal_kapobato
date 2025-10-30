import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _yearLevelController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // Education-related fields
  String? _selectedEducationLevel;
  String? _selectedCourse;
  String? _selectedStrand;

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
    _yearLevelController.dispose();
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
            _selectedEducationLevel = studentResponse['education_level'];
            _selectedCourse = studentResponse['course'];
            _selectedStrand = studentResponse['strand'];
            _yearLevelController.text = studentResponse['year_level']?.toString() ?? '';
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
      
      // Prepare student data update
      Map<String, dynamic> studentData = {
        'first_name': firstName,
        'last_name': lastName,
        'year_level': int.tryParse(_yearLevelController.text.trim()),
      };

      // Add education-specific fields
      if (_selectedEducationLevel == 'college') {
        studentData['education_level'] = 'college';
        studentData['course'] = _selectedCourse;
        studentData['strand'] = null;
      } else if (_selectedEducationLevel == 'senior_high') {
        studentData['education_level'] = 'senior_high';
        studentData['course'] = null;
        studentData['strand'] = _selectedStrand;
      } else if (_selectedEducationLevel == 'junior_high') {
        studentData['education_level'] = 'junior_high';
        studentData['course'] = null;
        studentData['strand'] = null;
      } else if (_selectedEducationLevel == 'basic_education') {
        studentData['education_level'] = 'basic_education';
        studentData['course'] = null;
        studentData['strand'] = null;
      }

      // Update in database
      await Supabase.instance.client
          .from('students')
          .update(studentData)
          .eq('user_id', userId);

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
        ? '${studentData!['first_name']} ${studentData!['last_name']}'
        : '';
    final studentCode = studentData?['student_code'] ?? '';

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
                      // First Name Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'First Name',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _firstNameController,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF3A3A50),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your first name',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Please enter your first name'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Last Name Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last Name',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _lastNameController,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF3A3A50),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your last name',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Please enter your last name'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Email Field (Disabled)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              enabled: false,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Education Level Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Education Level',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedEducationLevel,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF3A3A50),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Select Education Level',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'basic_education',
                                  child: Text('Basic Education (Grades 1-6)'),
                                ),
                                DropdownMenuItem(
                                  value: 'junior_high',
                                  child: Text('Junior High School (Grades 7-10)'),
                                ),
                                DropdownMenuItem(
                                  value: 'senior_high',
                                  child: Text('Senior High School (Grades 11-12)'),
                                ),
                                DropdownMenuItem(
                                  value: 'college',
                                  child: Text('College'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedEducationLevel = value;
                                  _selectedCourse = null;
                                  _selectedStrand = null;
                                  _yearLevelController.clear();
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Please select your education level' : null,
                              isExpanded: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Course Dropdown (for college)
                      if (_selectedEducationLevel == 'college')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Course/Program',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF3A3A50),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedCourse,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF3A3A50),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Select Course/Program',
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Bachelor of Science in Computer Science', child: Text('Bachelor of Science in Computer Science')),
                                  DropdownMenuItem(value: 'Bachelor of Science in Information Technology', child: Text('Bachelor of Science in Information Technology')),
                                  DropdownMenuItem(value: 'Bachelor of Science in Computer Engineering', child: Text('Bachelor of Science in Computer Engineering')),
                                  DropdownMenuItem(value: 'Bachelor of Science in Software Engineering', child: Text('Bachelor of Science in Software Engineering')),
                                  DropdownMenuItem(value: 'Bachelor of Arts in Psychology', child: Text('Bachelor of Arts in Psychology')),
                                  DropdownMenuItem(value: 'Bachelor of Science in Business Administration', child: Text('Bachelor of Science in Business Administration')),
                                  DropdownMenuItem(value: 'Bachelor of Science in Nursing', child: Text('Bachelor of Science in Nursing')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCourse = value;
                                  });
                                },
                                validator: (value) =>
                                    value == null ? 'Please select your course' : null,
                                isExpanded: true,
                              ),
                            ),
                          ],
                        ),

                      // Strand Dropdown (for senior high)
                      if (_selectedEducationLevel == 'senior_high')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Strand',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF3A3A50),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedStrand,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF3A3A50),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Select Strand',
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'STEM (Science, Technology, Engineering, and Mathematics)', child: Text('STEM')),
                                  DropdownMenuItem(value: 'ABM (Accountancy, Business, and Management)', child: Text('ABM')),
                                  DropdownMenuItem(value: 'HUMSS (Humanities and Social Sciences)', child: Text('HUMSS')),
                                  DropdownMenuItem(value: 'GAS (General Academic Strand)', child: Text('GAS')),
                                  DropdownMenuItem(value: 'TVL (Technical-Vocational-Livelihood)', child: Text('TVL')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStrand = value;
                                  });
                                },
                                validator: (value) =>
                                    value == null ? 'Please select your strand' : null,
                                isExpanded: true,
                              ),
                            ),
                          ],
                        ),

                      // Year Level Field (conditional based on education level)
                      if (_selectedEducationLevel != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              _selectedEducationLevel == 'basic_education'
                                  ? 'Grade Level (1-6)'
                                  : _selectedEducationLevel == 'junior_high'
                                      ? 'Grade Level (7-10)'
                                      : _selectedEducationLevel == 'senior_high'
                                          ? 'Grade Level (11-12)'
                                          : 'Year Level (1-4)',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF3A3A50),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextFormField(
                                controller: _yearLevelController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF3A3A50),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter year/grade level',
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter year/grade level';
                                  }
                                  final level = int.tryParse(value);
                                  if (level == null) {
                                    return 'Please enter a valid number';
                                  }
                                  if (_selectedEducationLevel == 'basic_education' && (level < 1 || level > 6)) {
                                    return 'Grade level must be between 1 and 6';
                                  }
                                  if (_selectedEducationLevel == 'junior_high' && (level < 7 || level > 10)) {
                                    return 'Grade level must be between 7 and 10';
                                  }
                                  if (_selectedEducationLevel == 'senior_high' && (level < 11 || level > 12)) {
                                    return 'Grade level must be between 11 and 12';
                                  }
                                  if (_selectedEducationLevel == 'college' && (level < 1 || level > 4)) {
                                    return 'Year level must be between 1 and 4';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

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
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
