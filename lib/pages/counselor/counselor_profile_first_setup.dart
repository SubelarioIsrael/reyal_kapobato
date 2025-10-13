import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/profile_image_service.dart';

class CounselorProfileFirstSetup extends StatefulWidget {
  const CounselorProfileFirstSetup({super.key});

  @override
  State<CounselorProfileFirstSetup> createState() => _CounselorProfileFirstSetupState();
}

class _CounselorProfileFirstSetupState extends State<CounselorProfileFirstSetup> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  
  String _selectedSpecialization = 'General Counseling';
  String _availability = 'available';
  bool _isLoading = false;
  bool _isUploading = false;
  String? _selectedImageBase64;
  String? _profileImageUrl;
  int? _counselorId;

  final List<String> _specializationOptions = const [
    'General Counseling',
    'Academic Counseling',
    'Career Counseling',
    'Mental Health Counseling',
    'Behavioral Counseling',
    'Family Counseling',
    'Group Counseling',
    'Crisis Counseling',
    'Substance Abuse Counseling',
    'Grief Counseling',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _emailController.text = user.email ?? '';
      
      // Try to get existing counselor profile
      final result = await Supabase.instance.client
          .from('counselors')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (result != null) {
        _counselorId = result['counselor_id'] as int?;
        _firstNameController.text = result['first_name'] ?? '';
        _lastNameController.text = result['last_name'] ?? '';
        _selectedSpecialization = result['specialization'] ?? 'General Counseling';
        _bioController.text = result['bio'] ?? '';
        _availability = result['availability_status'] ?? 'available';
        _profileImageUrl = result['profile_picture'];
      }
    } catch (e) {
      print('Error loading existing profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final String? base64Image = await ProfileImageService.showImageSourceDialog(context);
      if (base64Image != null) {
        setState(() {
          _selectedImageBase64 = base64Image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedImageBase64 == null) return _profileImageUrl;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      // Update counselor profile with base64 image data
      final success = await ProfileImageService.updateCounselorProfileImage(
        _selectedImageBase64!,
        user.id,
      );

      if (success) {
        return _selectedImageBase64;
      } else {
        throw Exception('Failed to update profile image');
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _completeSetup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload profile image if selected
      String? imageUrl = await _uploadProfileImage();

      final payload = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'specialization': _selectedSpecialization,
        'availability_status': _availability,
        'bio': _bioController.text.trim(),
        'profile_picture': imageUrl,
        'user_id': user.id,
      };

      if (_counselorId == null) {
        // Create new counselor record
        final inserted = await Supabase.instance.client
            .from('counselors')
            .insert(payload)
            .select()
            .single();
        _counselorId = inserted['counselor_id'] as int?;
      } else {
        // Update existing counselor record
        await Supabase.instance.client
            .from('counselors')
            .update(payload)
            .eq('counselor_id', _counselorId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile setup completed successfully!')),
        );
        
        // Navigate to counselor home
        Navigator.pushNamedAndRemoveUntil(
          context,
          'counselor-home',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation - this is required setup
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 242, 241, 248),
          elevation: 0,
          automaticallyImplyLeading: false, // Remove back button
          title: Text(
            "Required Profile Setup",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A3A50),
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Welcome Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C83FD).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF7C83FD).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.assignment_ind,
                                size: 48,
                                color: const Color(0xFF7C83FD),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Welcome to Breathe Better!',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3A3A50),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please complete your profile setup to start helping students. This is required before you can access the counselor dashboard.',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Profile Picture Section
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _selectedImageBase64 != null
                                  ? MemoryImage(base64Decode(_selectedImageBase64!))
                                  : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                      ? MemoryImage(base64Decode(_profileImageUrl!))
                                      : null),
                              child: (_selectedImageBase64 == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                                  ? Text(
                                      _firstNameController.text.isNotEmpty
                                          ? _firstNameController.text[0].toUpperCase()
                                          : 'C',
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
                                  onTap: _isUploading ? null : _pickImage,
                                  child: Icon(
                                    _isUploading
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
                        const SizedBox(height: 32),

                        // Form Fields
                        _buildTextField(
                          controller: _firstNameController,
                          label: 'First Name *',
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Please enter your first name'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _lastNameController,
                          label: 'Last Name *',
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

                        // Specialization Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedSpecialization,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF3A3A50),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Specialization *',
                            labelStyle: GoogleFonts.poppins(
                              color: const Color(0xFF3A3A50),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: _specializationOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedSpecialization = newValue ?? 'General Counseling';
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _bioController,
                          label: 'Professional Bio (Optional)',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        
                        Text(
                          '* Required fields',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Complete Setup Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _completeSetup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C83FD),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Complete Setup & Continue',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          'You must complete this setup to access your counselor dashboard.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF7C83FD),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
}