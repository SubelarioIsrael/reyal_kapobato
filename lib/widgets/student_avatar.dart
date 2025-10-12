import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentAvatar extends StatefulWidget {
  final String userId;
  final double radius;
  final String? fallbackName;
  final bool showOnlineIndicator;

  const StudentAvatar({
    super.key,
    required this.userId,
    this.radius = 30,
    this.fallbackName,
    this.showOnlineIndicator = false,
  });

  @override
  State<StudentAvatar> createState() => _StudentAvatarState();
}

class _StudentAvatarState extends State<StudentAvatar> {
  String? _profilePicture;
  String? _studentName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    if (!mounted) return;
    
    try {
      // Get student profile picture from users table and name from students table
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('profile_picture')
          .eq('user_id', widget.userId)
          .maybeSingle();

      final studentResponse = await Supabase.instance.client
          .from('students')
          .select('first_name, last_name')
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _profilePicture = userResponse?['profile_picture'];
          
          if (studentResponse != null &&
              studentResponse['first_name'] != null &&
              studentResponse['last_name'] != null) {
            _studentName = '${studentResponse['first_name']} ${studentResponse['last_name']}';
          } else {
            _studentName = widget.fallbackName;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading student profile: $e');
      if (mounted) {
        setState(() {
          _studentName = widget.fallbackName;
          _isLoading = false;
        });
      }
    }
  }

  String _getInitials() {
    if (_studentName?.isNotEmpty == true) {
      final names = _studentName!.trim().split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else if (names.isNotEmpty) {
        return names[0].length >= 2 
            ? names[0].substring(0, 2).toUpperCase()
            : names[0][0].toUpperCase();
      }
    }
    return 'S';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.grey[300],
        child: SizedBox(
          width: widget.radius * 0.6,
          height: widget.radius * 0.6,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      );
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: widget.radius,
          backgroundColor: const Color(0xFF7C83FD).withOpacity(0.1),
          backgroundImage: _profilePicture != null && _profilePicture!.isNotEmpty
              ? MemoryImage(base64Decode(_profilePicture!))
              : null,
          child: _profilePicture == null || _profilePicture!.isEmpty
              ? Text(
                  _getInitials(),
                  style: GoogleFonts.poppins(
                    fontSize: widget.radius * 0.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7C83FD),
                  ),
                )
              : null,
        ),
        if (widget.showOnlineIndicator)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: widget.radius * 0.4,
              height: widget.radius * 0.4,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}