import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CounselorProfileView extends StatefulWidget {
  final int counselorId;

  const CounselorProfileView({super.key, required this.counselorId});

  @override
  State<CounselorProfileView> createState() => _CounselorProfileViewState();
}

class _CounselorProfileViewState extends State<CounselorProfileView> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await Supabase.instance.client
          .from('counselors')
          .select()
          .eq('counselor_id', widget.counselorId)
          .maybeSingle();
      setState(() {
        _data = res;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _data == null
        ? ''
        : '${(_data!['first_name'] ?? '').toString()} ${(_data!['last_name'] ?? '').toString()}'
            .trim();
    final specialization = _data?['specialization']?.toString() ?? '';
    final availability = _data?['availability_status']?.toString() ?? '';
    final bio = _data?['bio']?.toString();
    final picture = _data?['profile_picture']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        title: Text(
          'Counselor Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3A3A50),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            const Color(0xFF7C83FD).withOpacity(0.1),
                        backgroundImage:
                            picture.isNotEmpty ? NetworkImage(picture) : null,
                        child: picture.isEmpty
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF7C83FD),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 24,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3A3A50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              specialization,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    (availability.toLowerCase() == 'available'
                                            ? Colors.green
                                            : Colors.orange)
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                availability,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color:
                                      availability.toLowerCase() == 'available'
                                          ? Colors.green
                                          : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'About',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (bio == null || bio.isEmpty) ? 'No bio provided.' : bio,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
