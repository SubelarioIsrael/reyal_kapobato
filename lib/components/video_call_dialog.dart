import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../services/video_call_service.dart';

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
  String? _generatedCallCode; // Store generated code

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
                  
                  if (_selectedOption == 'generate') ...[
                    const SizedBox(height: 16),
                    if (_generatedCallCode != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C83FD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF7C83FD).withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.code, color: Color(0xFF7C83FD)),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Call Code:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3A3A50),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _generatedCallCode!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      color: const Color(0xFF7C83FD),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: _generatedCallCode!));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Call code copied to clipboard!'),
                                          backgroundColor: Color(0xFF7C83FD),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C83FD).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.copy, size: 16, color: Color(0xFF7C83FD)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Share this code with your student to join the call',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF5D5D72),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () async {
                            setState(() {
                              _isLoading = true;
                            });
                            
                            try {
                              // Generate call code
                              final code = await _generateCallCodeDirectly();
                              setState(() {
                                _generatedCallCode = code;
                                _isLoading = false;
                              });
                            } catch (e) {
                              setState(() {
                                _isLoading = false;
                              });
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  contentPadding: const EdgeInsets.all(24),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Error Icon
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
                                      // Error Title
                                      Text(
                                        'Generation Failed',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF3A3A50),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Error Message
                                      Text(
                                        'Error generating code: $e',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: const Color(0xFF5D5D72),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      // OK Button
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
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C83FD),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(
                            _isLoading ? 'Generating...' : 'Generate Call Code',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                  
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
                          _generatedCallCode = null;
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
                            'Start Call',
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

  Future<String> _generateCallCodeDirectly() async {
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
      final callCode = _generateCallCode();

      // Save to database
      await Supabase.instance.client.from('video_calls').insert({
        'call_code': callCode,
        'counselor_id': counselorId,
        'created_by': 'counselor',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      return callCode;
    } catch (e) {
      throw Exception('Failed to generate code: $e');
    }
  }

  Future<void> _handleVideoCall() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Not logged in');
      }

      // Get counselor ID
      final counselorProfile = await Supabase.instance.client
          .from('counselors')
          .select('counselor_id')
          .eq('user_id', user.id)
          .single();

      final counselorId = counselorProfile['counselor_id'] as int;

      if (_selectedOption == 'generate' && _generatedCallCode != null) {
        // Join the generated call
        final codeToJoin = _generatedCallCode!;
        _joinVideoCall(codeToJoin);
      } else if (_selectedOption == 'enter') {
        // Enter existing code
        final callCode = _codeController.text.trim().toLowerCase();
        
        if (callCode.isEmpty) {
          setState(() => _isLoading = false);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Warning Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Warning Title
                  Text(
                    'Code Required',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Warning Message
                  Text(
                    'Please enter a call code',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF5D5D72),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // OK Button
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
          return;
        }

        if (callCode.length < 3) {
          setState(() => _isLoading = false);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error Icon
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
                  // Error Title
                  Text(
                    'Invalid Code Format',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Error Message
                  Text(
                    'Call code is too short. Please enter a valid code.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF5D5D72),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // OK Button
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
          setState(() => _isLoading = false);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error Icon
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
                  // Error Title
                  Text(
                    'Call Not Found',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Error Message
                  Text(
                    'This call code does not exist or has already ended.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF5D5D72),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // OK Button
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

        _joinVideoCall(callCode);
      }
    } catch (e) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Icon
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
              // Error Title
              Text(
                'Error',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 12),
              // Error Message
              Text(
                'An error occurred: $e',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                ),
              ),
              const SizedBox(height: 24),
              // OK Button
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

  Future<void> _joinVideoCall(String callCode) async {
    // Get current user information
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }
    
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
    if (!mounted) {
      return;
    }
    
    // Navigate to CallPage
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
    ).then((_) {
      // Close the video call dialog after returning from call
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}