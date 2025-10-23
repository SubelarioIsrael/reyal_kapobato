import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/counselor_avatar.dart';
import '../../components/student_notification_button.dart';

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
          .select('*, users!inner(email)')
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
    final email = _data?['users']?['email']?.toString() ?? '';
    final yearsOfExperience = _data?['years_of_experience']?.toString() ?? '';
    final education = _data?['education']?.toString() ?? '';
    final languages = _data?['languages']?.toString() ?? '';
    final workSchedule = _data?['work_schedule']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF5D5D72)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Counselor Profile",
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C83FD)),
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [

                  // Profile Picture Section - Centered
                  CounselorAvatar(
                    counselorId: widget.counselorId,
                    radius: 60,
                    fallbackName: name,
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3A3A50),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Specialization
                  Text(
                    specialization,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Availability Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (availability.toLowerCase() == 'available'
                              ? Colors.green
                              : Colors.orange)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      availability,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: availability.toLowerCase() == 'available'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Professional Information
                  if (yearsOfExperience.isNotEmpty)
                    _buildSimpleInfoCard('Experience', '$yearsOfExperience years'),
                  if (education.isNotEmpty)
                    _buildSimpleInfoCard('Education', education),
                  if (languages.isNotEmpty)
                    _buildSimpleInfoCard('Languages', languages),
                  if (workSchedule.isNotEmpty)
                    _buildSimpleInfoCard('Schedule', workSchedule),
                  if (email.isNotEmpty)
                    _buildSimpleInfoCard('Email', email),

                  // Bio/About Section
                  if (bio != null && bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            bio,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }



  Widget _buildSimpleInfoCard(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A3A50),
            ),
          ),
        ],
      ),
    );
  }
}
