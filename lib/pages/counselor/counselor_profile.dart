import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CounselorProfile extends StatefulWidget {
  const CounselorProfile({super.key});

  @override
  State<CounselorProfile> createState() => _CounselorProfileState();
}

class _CounselorProfileState extends State<CounselorProfile> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _specializationController =
      TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _profilePictureController =
      TextEditingController();

  String _availability = 'available';
  bool _isLoading = false;
  int? _counselorId;

  final List<String> _availabilityOptions = const [
    'available',
    'busy',
    'away',
    'offline',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      _emailController.text = user.email ?? '';
      final result = await Supabase.instance.client
          .from('counselors')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (result != null) {
        _counselorId = result['counselor_id'] as int?;
        _firstNameController.text = (result['first_name'] ?? '') as String;
        _lastNameController.text = (result['last_name'] ?? '') as String;
        _emailController.text = (result['email'] ?? '') as String;
        _specializationController.text =
            (result['specialization'] ?? '') as String;
        _bioController.text = (result['bio'] ?? '') as String;
        _profilePictureController.text =
            (result['profile_picture'] ?? '') as String;
        final availability =
            (result['availability_status'] ?? 'available') as String;
        if (_availabilityOptions.contains(availability)) {
          _availability = availability;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
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

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    final payload = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'specialization': _specializationController.text.trim(),
      'availability_status': _availability,
      'bio': _bioController.text.trim(),
      'profile_picture': _profilePictureController.text.trim().isEmpty
          ? null
          : _profilePictureController.text.trim(),
      'user_id': user.id,
    };

    try {
      if (_counselorId == null) {
        final inserted = await Supabase.instance.client
            .from('counselors')
            .insert(payload)
            .select()
            .single();
        _counselorId = inserted['counselor_id'] as int?;
      } else {
        await Supabase.instance.client
            .from('counselors')
            .update(payload)
            .eq('counselor_id', _counselorId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
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
    _specializationController.dispose();
    _bioController.dispose();
    _profilePictureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        title: Text(
          'My Profile',
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
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileHeader(
                      imageUrl: _profilePictureController.text.trim(),
                      fallbackInitials:
                          '${_firstNameController.text.isNotEmpty ? _firstNameController.text[0] : ''}${_lastNameController.text.isNotEmpty ? _lastNameController.text[0] : ''}',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _profilePictureController,
                      decoration: const InputDecoration(
                        labelText: 'Profile picture URL (optional)',
                        prefixIcon: Icon(Icons.link),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First name',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last name',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email (from account)',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _specializationController,
                      decoration: const InputDecoration(
                        labelText: 'Specialization',
                        prefixIcon: Icon(Icons.star_half_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _availability,
                      decoration: const InputDecoration(
                        labelText: 'Availability',
                        prefixIcon: Icon(Icons.circle_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: _availabilityOptions
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _availability = v ?? 'available';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveProfile,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C83FD),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String imageUrl;
  final String fallbackInitials;

  const _ProfileHeader({
    required this.imageUrl,
    required this.fallbackInitials,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = const Color(0xFF7C83FD).withOpacity(0.1);
    final Color fg = const Color(0xFF7C83FD);
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: bg,
          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty
              ? Text(
                  fallbackInitials.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Update your public profile',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3A3A50),
            ),
          ),
        )
      ],
    );
  }
}
