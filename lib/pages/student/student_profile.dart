import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/profile_image_service.dart';
import '../../components/student_notification_button.dart';
import '../../utils/department_mapping.dart';
import '../../controllers/student_profile_controller.dart';

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  final _controller = StudentProfileController();
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
    setState(() {
      isLoading = true;
    });

    final result = await _controller.loadUserProfile();

    if (mounted) {
      setState(() {
        isLoading = false;
      });

      if (result.success && result.data != null) {
        final userResponse = result.data!['user'];
        final studentResponse = result.data!['student'];

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
        });
      } else {
        _showErrorDialog(result.errorMessage ?? 'Failed to load profile');
      }
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Error',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'OK',
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
      );
    }
  }

  void _showSuccessDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Success',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'OK',
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
      );
    }
  }

  Future<void> _uploadImage() async {
    setState(() {
      isUploading = true;
    });

    try {
      // Show image source selection dialog
      final String? selectedImageBase64 = await ProfileImageService.showImageSourceDialog(context);
      
      if (selectedImageBase64 == null) {
        setState(() {
          isUploading = false;
        });
        return;
      }

      // Update profile image using controller
      final result = await _controller.updateProfilePicture(
        base64Image: selectedImageBase64,
      );

      if (result.success) {
        // Reload the profile
        await _loadUserProfile();
        if (mounted) {
          _showSuccessDialog('Profile picture updated successfully');
        }
      } else {
        if (mounted) {
          _showErrorDialog(result.errorMessage ?? 'Failed to update profile picture');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error: ${e.toString()}');
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
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      final result = await _controller.updateProfile(
        firstName: firstName,
        lastName: lastName,
        educationLevel: _selectedEducationLevel!,
        course: _selectedCourse,
        strand: _selectedStrand,
        yearLevel: int.tryParse(_yearLevelController.text.trim()),
      );

      if (result.success) {
        await _loadUserProfile();
        if (mounted) {
          _showSuccessDialog('Profile updated successfully');
        }
      } else {
        if (mounted) {
          _showErrorDialog(result.errorMessage ?? 'Failed to update profile');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error: ${e.toString()}');
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
    const pastelBlue = Color.fromARGB(255, 242, 241, 248);
    final studentName = studentData != null
        ? '${studentData!['first_name']} ${studentData!['last_name']}'
        : '';
    final studentCode = studentData?['student_code'] ?? '';

    return Scaffold(

      backgroundColor: pastelBlue,
        appBar: AppBar(
          backgroundColor: pastelBlue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF5D5D72)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "Student Profile",
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
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
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
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your first name';
                                }
                                if (!_controller.isValidName(value)) {
                                  return 'Name can only contain letters, spaces, hyphens, and apostrophes';
                                }
                                return null;
                              },
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
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your last name';
                                }
                                if (!_controller.isValidName(value)) {
                                  return 'Name can only contain letters, spaces, hyphens, and apostrophes';
                                }
                                return null;
                              },
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
                                  child: Text('Basic Education (Grades 1-10)'),
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
                                items: DepartmentMapping.collegePrograms.map((course) {
                                  return DropdownMenuItem<String>(
                                    value: course,
                                    child: Text(
                                      course,
                                      style: GoogleFonts.poppins(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
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
                                items: DepartmentMapping.seniorHighStrands.map((strand) {
                                  return DropdownMenuItem<String>(
                                    value: strand,
                                    child: Text(
                                      strand,
                                      style: GoogleFonts.poppins(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
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
                                  ? 'Grade Level (1-10)'
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
                                  if (_selectedEducationLevel == 'basic_education' && (level < 1 || level > 10)) {
                                    return 'Grade level must be between 1 and 10';
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

                      // Save Changes Button
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
                                  'Save Changes',
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
