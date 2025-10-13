import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CounselorAvatar extends StatefulWidget {
  final String? userId;
  final int? counselorId;
  final double radius;
  final String? fallbackName;
  final bool showOnlineIndicator;

  const CounselorAvatar({
    super.key,
    this.userId,
    this.counselorId,
    this.radius = 30,
    this.fallbackName,
    this.showOnlineIndicator = false,
  });

  @override
  State<CounselorAvatar> createState() => _CounselorAvatarState();
}

class _CounselorAvatarState extends State<CounselorAvatar> {
  String? _profilePicture;
  String? _counselorName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounselorProfile();
  }

  Future<void> _loadCounselorProfile() async {
    if (!mounted) return;
    
    try {
      String? profilePicture;
      String? counselorName;

      if (widget.counselorId != null) {
        // Load by counselor ID - join counselors and users tables to get profile picture from users table
        final response = await Supabase.instance.client
            .from('counselors')
            .select('first_name, last_name, user_id, users!inner(profile_picture)')
            .eq('counselor_id', widget.counselorId!)
            .maybeSingle();

        if (response != null) {
          profilePicture = response['users']?['profile_picture'];
          final firstName = response['first_name'];
          final lastName = response['last_name'];
          if (firstName != null && lastName != null) {
            counselorName = '$firstName $lastName';
          }
          print('CounselorAvatar: Loaded for counselorId ${widget.counselorId}, name: $counselorName, has profile picture: ${profilePicture?.isNotEmpty == true}');
        }
      } else if (widget.userId != null) {
        // Load by user ID - get counselor info and profile picture from users table
        final counselorResponse = await Supabase.instance.client
            .from('counselors')
            .select('first_name, last_name')
            .eq('user_id', widget.userId!)
            .maybeSingle();

        final userResponse = await Supabase.instance.client
            .from('users')
            .select('profile_picture')
            .eq('user_id', widget.userId!)
            .maybeSingle();

        profilePicture = userResponse?['profile_picture'];
        
        if (counselorResponse != null) {
          final firstName = counselorResponse['first_name'];
          final lastName = counselorResponse['last_name'];
          if (firstName != null && lastName != null) {
            counselorName = '$firstName $lastName';
          }
        }
      }

      if (mounted) {
        setState(() {
          _profilePicture = profilePicture;
          _counselorName = counselorName ?? widget.fallbackName;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading counselor profile: $e');
      if (mounted) {
        setState(() {
          _counselorName = widget.fallbackName;
          _isLoading = false;
        });
      }
    }
  }

  String _getInitials() {
    if (_counselorName?.isNotEmpty == true) {
      final names = _counselorName!.trim().split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else if (names.isNotEmpty) {
        return names[0].length >= 2 
            ? names[0].substring(0, 2).toUpperCase()
            : names[0][0].toUpperCase();
      }
    }
    return 'C';
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