import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Phase 1 - Login Info
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Phase 2 - Personal Info
  final _studentIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String? _selectedEducationLevel; // 'basic_education', 'junior_high', 'senior_high', or 'college'
  String? _selectedCourse;
  String? _selectedStrand;
  final _yearLevelController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Phase control
  int _currentPhase = 1;

  Future<void> _handlePhase1() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Check for duplicates without creating account yet
        final email = _emailController.text.trim();

        // Check email in users table
        final emailExists = await Supabase.instance.client
            .from('users')
            .select('user_id')
            .eq('email', email)
            .maybeSingle();

        if (emailExists != null) {
          _showErrorDialog(
            'Account Already Exists',
            'An account with this email address already exists. Please use a different email address.',
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Just move to phase 2 without creating account yet
        setState(() {
          _currentPhase = 2;
          _isLoading = false;
        });
      } catch (e) {
        print('Phase 1 validation error: $e');
        _showErrorDialog('Validation Failed',
            'Something went wrong. Please try again later.');
      } finally {
        if (context.mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handlePhase2() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final studentCode = _studentIdController.text.trim();

        // Check if student_code already exists
        final studentCodeExists = await Supabase.instance.client
            .from('students')
            .select('user_id')
            .eq('student_code', studentCode)
            .maybeSingle();

        if (studentCodeExists != null) {
          _showErrorDialog(
            'Student ID Already Exists',
            'This Student ID is already registered. Please use a different Student ID.',
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Now create the account with Supabase Auth
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: email,
          password: _passwordController.text.trim(),
          emailRedirectTo: 'breathebetter://verify-email',
        );

        final user = authResponse.user;

        // Check if auth was successful but user is null (shouldn't happen but better to be safe)
        if (user == null) {
          _showErrorDialog(
            'Registration Failed', 
            'Account creation failed. Please try again.'
          );
          return;
        }

        // Check if user already exists in our users table (to prevent duplicates)
          final existingUser = await Supabase.instance.client
              .from('users')
              .select('user_id')
              .eq('user_id', user.id)
              .maybeSingle();

          if (existingUser == null) {
            // Insert into the 'users' table only if not exists
            await Supabase.instance.client.from('users').insert({
              'user_id': user.id,
              'email': email,
              'registration_date': DateTime.now().toIso8601String(),
              'user_type': 'student',
              'status': 'active',
            });
          }

          // Check if student record already exists (to prevent duplicates)
          final existingStudent = await Supabase.instance.client
              .from('students')
              .select('user_id')
              .eq('user_id', user.id)
              .maybeSingle();

          if (existingStudent == null) {
            // Prepare student data
            Map<String, dynamic> studentData = {
              'user_id': user.id,
              'student_code': studentCode,
              'first_name': _firstNameController.text.trim(),
              'last_name': _lastNameController.text.trim(),
              'year_level': int.tryParse(_yearLevelController.text.trim()),
            };

            // Add education-specific fields based on education level
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

            // Insert into the 'students' table
            await Supabase.instance.client.from('students').insert(studentData);
          }

          // Show success and email verification dialog
          _showSuccessDialog();
        
      } on AuthException catch (e) {
        print('Supabase Auth error: ${e.message}');
        String errorMessage = 'Registration failed. Please try again.';
        
        if (e.message.contains('For security purposes, you can only request this after')) {
          // Rate limiting error
          final match = RegExp(r'after (\d+) seconds?').firstMatch(e.message);
          final seconds = match?.group(1) ?? '13';
          errorMessage = 'Please wait $seconds seconds before trying to register again.';
        } else if (e.message.contains('email')) {
          errorMessage = 'Invalid email address or email already in use.';
        } else if (e.message.contains('password')) {
          errorMessage = 'Password is too weak. Please use a stronger password.';
        } else if (e.message.contains('User already registered')) {
          errorMessage = 'An account with this email already exists. Please use a different email or try signing in.';
        }
        
        _showErrorDialog('Registration Failed', errorMessage);
      } catch (e) {
        print('Phase 2 signup error: $e');
        _showErrorDialog('Registration Failed',
            'Something went wrong. Please try again later.');
      } finally {
        if (context.mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _goBackToPhase1() {
    setState(() {
      _currentPhase = 1;
    });
  }

  String _getYearLevelHint() {
    switch (_selectedEducationLevel) {
      case 'basic_education':
        return 'Grade Level (1-6)';
      case 'junior_high':
        return 'Grade Level (7-10)';
      case 'senior_high':
        return 'Grade Level (11-12)';
      case 'college':
        return 'Year Level (1-4)';
      default:
        return 'Select Education Level First';
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.red.shade700,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7C83FD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Account Created Successfully!',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4CAF50),
          ),
        ),
        content: Text(
          'A verification link has been sent to ${_emailController.text.trim()}.\n\nPlease check your inbox and click the link to verify your email before logging in.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text(
              'Go to Login',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7C83FD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                const Icon(Icons.spa, size: 80, color: Color(0xFF81C784)),
                const SizedBox(height: 20),
                // Title
                Text(
                  "BreatheBetter",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4F646F),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  _currentPhase == 1
                      ? "Create your account to get started"
                      : "Complete your profile information",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 40),
                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step indicator text
                        Text(
                          _currentPhase == 1
                              ? 'Login Information'
                              : 'Personal Information',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Phase content
                        _currentPhase == 1 ? _buildPhase1() : _buildPhase2(),

                        const SizedBox(height: 32),

                        // Navigation Buttons
                        _currentPhase == 1
                            ? _buildPhase1Buttons()
                            : _buildPhase2Buttons(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Login Link (only show in phase 1)
                if (_currentPhase == 1)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: "Sign In",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF7C83FD),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhase1() {
    return Column(
      children: [
        // Email Field
        TextFormField(
          key: const Key('signup_email'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: 'Email Address',
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
            prefixIcon:
                const Icon(Icons.email_outlined, color: Color(0xFF7C83FD)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email address';
            }
            final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
            return emailRegex.hasMatch(value)
                ? null
                : 'Please enter a valid email address';
          },
        ),
        const SizedBox(height: 16),

        // Password Field
        TextFormField(
          key: const Key('signup_password'),
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: 'Password',
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
            prefixIcon:
                const Icon(Icons.lock_outline, color: Color(0xFF7C83FD)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade600,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Confirm Password Field
        TextFormField(
          key: const Key('signup_confirm_password'),
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: 'Confirm Password',
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
            prefixIcon:
                const Icon(Icons.lock_outline, color: Color(0xFF7C83FD)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: Colors.grey.shade600,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhase2() {
    // Course options based on education level
    final List<String> collegePrograms = [
      'Bachelor of Science in Computer Science',
      'Bachelor of Science in Information Technology',
      'Bachelor of Science in Computer Engineering',
      'Bachelor of Science in Software Engineering',
      'Bachelor of Arts in Psychology',
      'Bachelor of Science in Business Administration',
      'Bachelor of Science in Nursing',
      // Add more programs as needed
    ];

    final List<String> strands = [
      'STEM (Science, Technology, Engineering, and Mathematics)',
      'ABM (Accountancy, Business, and Management)',
      'HUMSS (Humanities and Social Sciences)',
      'GAS (General Academic Strand)',
      'TVL (Technical-Vocational-Livelihood)',
    ];

    return Column(
      children: [
        // Student ID Field
        TextFormField(
          controller: _studentIdController,
          keyboardType: TextInputType.text,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: 'Student ID Number',
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
            prefixIcon:
                const Icon(Icons.card_membership, color: Color(0xFF7C83FD)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) => value?.isEmpty ?? true
              ? 'Please enter your student ID number'
              : null,
        ),
        const SizedBox(height: 16),
        // First Name Field
        TextFormField(
          controller: _firstNameController,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: 'First Name',
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
            prefixIcon: const Icon(Icons.person, color: Color(0xFF7C83FD)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter your first name' : null,
        ),
        const SizedBox(height: 16),

        // Last Name Field
        TextFormField(
          controller: _lastNameController,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: 'Last Name',
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
            prefixIcon: const Icon(Icons.person, color: Color(0xFF7C83FD)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter your last name' : null,
        ),
        const SizedBox(height: 16),

        // Education Level Dropdown
        DropdownButtonFormField<String>(
          value: _selectedEducationLevel,
          style: GoogleFonts.poppins(color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'Select Education Level',
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
            prefixIcon: const Icon(Icons.school, color: Color(0xFF7C83FD)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
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
            });
          },
          validator: (value) =>
              value == null ? 'Please select your education level' : null,
          isExpanded: true,
        ),
        const SizedBox(height: 16),

        // Course/Strand Dropdown (conditional)
        if (_selectedEducationLevel == 'college')
          DropdownButtonFormField<String>(
            value: _selectedCourse,
            style: GoogleFonts.poppins(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Select Course/Program',
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
              prefixIcon:
                  const Icon(Icons.library_books, color: Color(0xFF7C83FD)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF7C83FD), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: collegePrograms.map((course) {
              return DropdownMenuItem<String>(
                value: course,
                child: Text(
                  course,
                  style: GoogleFonts.poppins(),
                  maxLines: 1,
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

        if (_selectedEducationLevel == 'senior_high')
          DropdownButtonFormField<String>(
            value: _selectedStrand,
            style: GoogleFonts.poppins(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Select Strand (if applicable)',
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
              prefixIcon:
                  const Icon(Icons.library_books, color: Color(0xFF7C83FD)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF7C83FD), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: strands.map((strand) {
              return DropdownMenuItem<String>(
                value: strand,
                child: Text(
                  strand,
                  style: GoogleFonts.poppins(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStrand = value;
              });
            },
            validator: (value) => _selectedEducationLevel == 'senior_high' && (value == null || value.isEmpty) 
                ? 'Please select a strand for Senior High School' 
                : null,
            isExpanded: true,
          ),

        const SizedBox(height: 16),

        // Year Level Field
        TextFormField(
          controller: _yearLevelController,
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: _getYearLevelHint(),
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
            prefixIcon:
                const Icon(Icons.calendar_today, color: Color(0xFF7C83FD)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your year/grade level';
            }
            final yearLevel = int.tryParse(value);
            if (yearLevel == null) {
              return 'Please enter a valid number';
            }
            
            // Validate based on selected education level
            switch (_selectedEducationLevel) {
              case 'basic_education':
                if (yearLevel < 1 || yearLevel > 6) {
                  return 'Basic Education grade level must be between 1 and 6';
                }
                break;
              case 'junior_high':
                if (yearLevel < 7 || yearLevel > 10) {
                  return 'Junior High grade level must be between 7 and 10';
                }
                break;
              case 'senior_high':
                if (yearLevel < 11 || yearLevel > 12) {
                  return 'Senior High grade level must be between 11 and 12';
                }
                break;
              case 'college':
                if (yearLevel < 1 || yearLevel > 4) {
                  return 'College year level must be between 1 and 4';
                }
                break;
              default:
                return 'Please select an education level first';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhase1Buttons() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C83FD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: _isLoading ? null : _handlePhase1,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Next',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildPhase2Buttons() {
    return Row(
      children: [
        // Back Button (left side)
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF7C83FD)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: _isLoading ? null : _goBackToPhase1,
              child: Text(
                'Back',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7C83FD),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Create Button (right side)
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C83FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: _isLoading ? null : _handlePhase2,
              child: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Create',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
