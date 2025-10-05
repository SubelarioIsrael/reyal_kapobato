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
  bool _isLoading = false;
  String _selectedOption = 'generate'; // 'generate' or 'enter'

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.video_call, color: Color(0xFF7C83FD), size: 28),
          const SizedBox(width: 12),
          Text(
            'Video Call',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A3A50),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose an option to start a video call:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF5D5D72),
            ),
          ),
          const SizedBox(height: 16),
          
          // Option 1: Generate Code
          RadioListTile<String>(
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Create a new call room for students to join',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF5D5D72),
              ),
            ),
            activeColor: const Color(0xFF7C83FD),
          ),
          
          // Option 2: Enter Code
          RadioListTile<String>(
            value: 'enter',
            groupValue: _selectedOption,
            onChanged: (value) {
              setState(() {
                _selectedOption = value!;
              });
            },
            title: Text(
              'Enter Call Code',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Join an existing call room',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF5D5D72),
              ),
            ),
            activeColor: const Color(0xFF7C83FD),
          ),
          
          if (_selectedOption == 'enter') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'Enter call code (e.g., abc-def-ghi)',
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              style: GoogleFonts.poppins(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              color: const Color(0xFF5D5D72),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleVideoCall,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C83FD),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _selectedOption == 'generate' ? 'Generate Code' : 'Join Call',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
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
        final callCode = _codeController.text.trim();
        if (callCode.isEmpty) {
          _showErrorSnackBar('Please enter a call code');
          return;
        }

        // Check if code exists and is active
        final existingCall = await Supabase.instance.client
            .from('video_calls')
            .select()
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
      try {
        final counselorData = await Supabase.instance.client
            .from('counselors')
            .select('first_name, last_name')
            .eq('user_id', user.id)
            .maybeSingle();
        
        if (counselorData != null && 
            counselorData['first_name'] != null && 
            counselorData['last_name'] != null) {
          userName = '${counselorData['first_name']} ${counselorData['last_name']}';
        }
      } catch (e) {
        // Fallback to email if counselor data fetch fails
        userName = user.email ?? 'Counselor';
      }
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CallPage(
            callID: callCode,
            userID: user.id,
            userName: userName,
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
    super.dispose();
  }
}