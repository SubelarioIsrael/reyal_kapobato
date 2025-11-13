import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/department_mapping.dart';
import '../controllers/user_controller.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Controller instance
  final _userController = UserController();

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
        final email = _emailController.text.trim();
        
        // Use controller to validate phase 1
        final result = await _userController.validateSignupPhase1(email);

        if (!result.success) {
          _showErrorDialog(
            result.errorTitle ?? 'Validation Failed',
            result.errorMessage ?? 'Something went wrong. Please try again.',
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Move to phase 2
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
        // Use controller to create student account
        final result = await _userController.createStudentAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          studentCode: _studentIdController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          educationLevel: _selectedEducationLevel!,
          course: _selectedCourse,
          strand: _selectedStrand,
          yearLevel: int.parse(_yearLevelController.text.trim()),
        );

        if (!result.success) {
          _showErrorDialog(
            result.errorTitle ?? 'Registration Failed',
            result.errorMessage ?? 'Something went wrong. Please try again.',
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Show success dialog
        _showSuccessDialog();
        
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
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
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A50),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF3A3A50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF7C83FD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
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
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Registration Successful!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A50),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Welcome to BreatheBetter!',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A verification link has been sent to:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: const Color(0xFF7C83FD),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _emailController.text.trim(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7C83FD),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please check your inbox and click the verification link before signing in.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF5D5D72),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF7C83FD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                'Go to Sign In',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentIdInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7C83FD).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Color(0xFF7C83FD),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Student ID Information',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A50),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Please refer to your Student ID for accurate information.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF3A3A50),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.card_membership,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Student ID Number',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your student ID number exactly as shown on your ID card.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF5D5D72),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Name',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your first and last name exactly as they appear on your student ID.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF5D5D72),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your information must match our records to proceed with registration.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF5D5D72),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF7C83FD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                'Got It',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
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
                Image.asset(
                  'assets/icon/breathebetterlogo2.png',
                  height: 80,
                  width: 80,
                  color: const Color(0xFF7C83FD), // optional tint
                ),
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
                        // Step indicator text with info button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                            if (_currentPhase == 2)
                              IconButton(
                                icon: Icon(
                                  Icons.info_outline,
                                  color: const Color(0xFF7C83FD),
                                  size: 20,
                                ),
                                onPressed: _showStudentIdInfoDialog,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Student ID Information',
                              ),
                          ],
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
            return _userController.validateEmail(value)
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
          validator: (value) => _userController.validatePassword(value ?? ''),
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
          validator: (value) => _userController.validatePasswordConfirmation(
            _passwordController.text,
            value ?? '',
          ),
        ),
      ],
    );
  }

  Widget _buildPhase2() {
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
          validator: (value) => _userController.validateStudentId(value ?? ''),
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
          validator: (value) => _userController.validateName(value ?? '', 'first name'),
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
          validator: (value) => _userController.validateName(value ?? '', 'last name'),
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
            items: DepartmentMapping.collegePrograms.map((course) {
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
            items: DepartmentMapping.seniorHighStrands.map((strand) {
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
          validator: (value) => _userController.validateYearLevel(
            value ?? '',
            _selectedEducationLevel,
          ),
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
