import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../call/call.dart';

class VideoCallDialog extends StatefulWidget {
  const VideoCallDialog({super.key});

  @override
  State<VideoCallDialog> createState() => _VideoCallDialogState();
}

class _VideoCallDialogState extends State<VideoCallDialog> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  String _selectedOption = 'generate'; // 'generate' or 'enter'

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF7C83FD).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C83FD).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.video_call,
                    color: Color(0xFF7C83FD),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video Call',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose an option to start your session',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF5D5D72),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF5D5D72)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Option 1: Generate Code
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedOption == 'generate'
                            ? const Color(0xFF7C83FD)
                            : Colors.grey.shade300,
                        width: _selectedOption == 'generate' ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RadioListTile<String>(
                      value: 'generate',
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value!;
                          _codeController.clear();
                        });
                      },
                      title: Text(
                        'Generate New Call Code',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      subtitle: Text(
                        'Create a new room for students to join',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF5D5D72),
                        ),
                      ),
                      activeColor: const Color(0xFF7C83FD),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Option 2: Enter Code
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedOption == 'enter'
                            ? const Color(0xFF7C83FD)
                            : Colors.grey.shade300,
                        width: _selectedOption == 'enter' ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RadioListTile<String>(
                      value: 'enter',
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value!;
                        });
                        if (value == 'enter') {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _focusNode.requestFocus();
                          });
                        }
                      },
                      title: Text(
                        'Join Existing Call',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      subtitle: Text(
                        'Enter a call code to join an existing room',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF5D5D72),
                        ),
                      ),
                      activeColor: const Color(0xFF7C83FD),
                    ),
                  ),
                  
                  if (_selectedOption == 'enter') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      focusNode: _focusNode,
                      autofocus: true,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Call Code',
                        hintText: 'Enter call code (abc-def-ghi)',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                        labelStyle: GoogleFonts.poppins(color: const Color(0xFF5D5D72)),
                        prefixIcon: Icon(Icons.code, color: Colors.grey.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      onSubmitted: (value) {
                        if (value.isNotEmpty && !_isLoading) {
                          _handleVideoCall();
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5D5D72),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVideoCall,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF7C83FD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _selectedOption == 'generate' ? 'Generate Code' : 'Join Call',
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
        ],
      ),
    );
  }

  Future<void> _handleVideoCall() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Get counselor ID
      final counselorProfile = await Supabase.instance.client
          .from('counselors')
          .select('counselor_id')
          .eq('user_id', user.id)
          .single();

      final counselorId = counselorProfile['counselor_id'] as int;

      if (_selectedOption == 'generate') {
        // Generate a new call code
        final callCode = _generateCallCode();
        
        // Save to database
        await Supabase.instance.client.from('video_calls').insert({
          'call_code': callCode,
          'counselor_id': counselorId,
          'created_by': 'counselor',
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
        });

        // Show success dialog with the generated code
        Navigator.pop(context);
        _showGeneratedCodeDialog(callCode);
      } else {
        // Enter existing code
        final callCode = _codeController.text.trim().toLowerCase();
        
        if (callCode.isEmpty) {
          _showErrorSnackBar('Please enter a call code');
          return;
        }

        if (callCode.length < 3) {
          _showErrorSnackBar('Call code is too short');
          return;
        }

        // Check if code exists and is active
        final existingCall = await Supabase.instance.client
            .from('video_calls')
            .select('*')
            .eq('call_code', callCode)
            .eq('status', 'active')
            .maybeSingle();

        if (existingCall == null) {
          _showErrorSnackBar('Call code does not exist or has expired');
          return;
        }

        // Update the call to include counselor
        await Supabase.instance.client
            .from('video_calls')
            .update({
              'counselor_id': counselorId,
              'counselor_joined_at': DateTime.now().toIso8601String(),
            })
            .eq('call_code', callCode);

        Navigator.pop(context);
        _joinVideoCall(callCode);
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateCallCode() {
    // Generate a Google Meet style code (xxx-xxx-xxx)
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    final random = Random();
    
    String generateSegment() {
      return List.generate(3, (index) => chars[random.nextInt(chars.length)]).join();
    }
    
    return '${generateSegment()}-${generateSegment()}-${generateSegment()}';
  }

  void _showGeneratedCodeDialog(String callCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text(
              'Call Code Generated',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3A3A50),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share this code with the student to join the call:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7C83FD).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7C83FD)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    callCode,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7C83FD),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: callCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy, color: Color(0xFF7C83FD)),
                    tooltip: 'Copy Code',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: const Color(0xFF5D5D72),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _joinVideoCall(callCode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C83FD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Join Call',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _joinVideoCall(String callCode) async {
    // Get current user information
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Try to get counselor info first, fallback to user email
      String userName = user.email ?? 'Counselor';
      int? appointmentId;
      String? studentUserId;
      int? counselorId;
      
      try {
        final counselorData = await Supabase.instance.client
            .from('counselors')
            .select('first_name, last_name, counselor_id')
            .eq('user_id', user.id)
            .maybeSingle();
        
        if (!mounted) return;
        
        if (counselorData != null) {
          counselorId = counselorData['counselor_id'];
          if (counselorData['first_name'] != null && 
              counselorData['last_name'] != null) {
            userName = '${counselorData['first_name']} ${counselorData['last_name']}';
          }
        }

        // Try to get video call details to find associated appointment and student
        final videoCallData = await Supabase.instance.client
            .from('video_calls')
            .select('student_user_id')
            .eq('call_code', callCode)
            .maybeSingle();

        if (!mounted) return;

        if (videoCallData != null) {
          studentUserId = videoCallData['student_user_id'];
          
          // Try to find today's appointment with this student
          if (studentUserId != null && counselorId != null) {
            final today = DateTime.now();
            final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
            
            final appointmentData = await Supabase.instance.client
                .from('counseling_appointments')
                .select('appointment_id')
                .eq('counselor_id', counselorId)
                .eq('user_id', studentUserId)
                .eq('appointment_date', todayStr)
                .eq('status', 'accepted')
                .maybeSingle();

            if (!mounted) return;

            if (appointmentData != null) {
              appointmentId = appointmentData['appointment_id'];
            }
          }
        }
      } catch (e) {
        // Fallback to email if counselor data fetch fails
        userName = user.email ?? 'Counselor';
      }
      
      // Check if widget is still mounted before navigating
      if (!mounted) return;
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CallPage(
            callID: callCode,
            userID: user.id,
            userName: userName,
            appointmentId: appointmentId,
            studentUserId: studentUserId,
            counselorId: counselorId,
          ),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}