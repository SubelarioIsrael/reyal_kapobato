import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/modern_form_dialog.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'counselor';
  String _selectedFilter = 'all';
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('*, students(*)')
          .order('email');

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _applyFilters();
      });
    } catch (e) {
      print('Error loading users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load users')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesType =
            _selectedFilter == 'all' || user['user_type'] == _selectedFilter;
        final matchesSearch = _searchController.text.isEmpty ||
            user['email']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            (user['students']?['student_code'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());
        return matchesType && matchesSearch;
      }).toList();
    });
  }

  Future<void> _toggleUserStatus(String userId, String currentStatus) async {
    try {
      final newStatus = currentStatus == 'active' ? 'suspended' : 'active';
      await Supabase.instance.client
          .from('users')
          .update({'status': newStatus}).eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'User ${newStatus == 'active' ? 'activated' : 'suspended'} successfully'),
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      print('Error updating user status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update user status')),
        );
      }
    }
  }

  Future<void> _deleteUserWithRelatedData(String userId) async {
    // Show confirmation dialog first
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
          'Are you sure you want to delete this user? This action will permanently remove the user and all their related data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Delete related data in proper order (from dependent to parent)
      // 1. Delete user notifications
      await Supabase.instance.client
          .from('user_notifications')
          .delete()
          .eq('user_id', userId);

      // 2. Delete questionnaire responses and answers
      final responses = await Supabase.instance.client
          .from('questionnaire_responses')
          .select('response_id')
          .eq('user_id', userId);
      
      for (var response in responses) {
        await Supabase.instance.client
            .from('questionnaire_answers')
            .delete()
            .eq('response_id', response['response_id']);
      }
      
      await Supabase.instance.client
          .from('questionnaire_responses')
          .delete()
          .eq('user_id', userId);

      // 3. Delete activity completions
      await Supabase.instance.client
          .from('activity_completions')
          .delete()
          .eq('user_id', userId);

      // 3b. Delete chat messages
      await Supabase.instance.client
          .from('chat_messages')
          .delete()
          .eq('user_id', userId);

      // 3c. Delete intervention logs
      await Supabase.instance.client
          .from('intervention_logs')
          .delete()
          .eq('user_id', userId);

      // 3d. Delete video calls (as student)
      await Supabase.instance.client
          .from('video_calls')
          .delete()
          .eq('student_user_id', userId);

      // 3e. Delete messages (as sender and receiver)
      await Supabase.instance.client
          .from('messages')
          .delete()
          .eq('sender_id', userId);
      
      await Supabase.instance.client
          .from('messages')
          .delete()
          .eq('receiver_id', userId);

      // 3f. Delete counseling session notes
      await Supabase.instance.client
          .from('counseling_session_notes')
          .delete()
          .eq('student_user_id', userId);

      // 4. Delete journal entries
      await Supabase.instance.client
          .from('journal_entries')
          .delete()
          .eq('user_id', userId);

      // 5. Delete mood entries
      await Supabase.instance.client
          .from('mood_entries')
          .delete()
          .eq('user_id', userId);

      // 6. Delete emergency contacts
      await Supabase.instance.client
          .from('emergency_contacts')
          .delete()
          .eq('user_id', userId);

      // 7. Delete counseling appointments (as student)
      await Supabase.instance.client
          .from('counseling_appointments')
          .delete()
          .eq('user_id', userId);
      
      // 7b. Delete counseling appointments and related data where user is the counselor
      // First get counselor_id for this user
      final counselorResponse = await Supabase.instance.client
          .from('counselors')
          .select('counselor_id')
          .eq('user_id', userId);
      
      if (counselorResponse.isNotEmpty) {
        final counselorId = counselorResponse[0]['counselor_id'];
        
        // Delete counseling appointments as counselor
        await Supabase.instance.client
            .from('counseling_appointments')
            .delete()
            .eq('counselor_id', counselorId);
            
        // Delete video calls as counselor
        await Supabase.instance.client
            .from('video_calls')
            .delete()
            .eq('counselor_id', counselorId);
            
        // Delete counseling session notes as counselor
        await Supabase.instance.client
            .from('counseling_session_notes')
            .delete()
            .eq('counselor_id', counselorId);
      }

      // 8. Tables password_resets and user_profiles don't exist in updated schema
      // Skipping deletion of these non-existent tables

      // 9. Delete role-specific records
      await Supabase.instance.client
          .from('students')
          .delete()
          .eq('user_id', userId);
      
      await Supabase.instance.client
          .from('counselors')
          .delete()
          .eq('user_id', userId);

      // 10. Finally, delete the main user record
      await Supabase.instance.client
          .from('users')
          .delete()
          .eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User and all related data deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      print('Error deleting user with related data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete user: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddUserDialog() {
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _selectedRole = 'counselor';
    _showPassword = false;
    _showConfirmPassword = false;
    
    ModernFormDialog.show(
      context: context,
      title: 'Add New User',
      subtitle: 'Create a new user account for the system',
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormSection(
              title: 'Account Information',
              icon: Icons.person_outline,
              child: ModernTextFormField(
                controller: _emailController,
                labelText: 'Email Address',
                hintText: 'Enter a valid email address',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter an email';
                  }
                  final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value!)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 32),
            FormSection(
              title: 'Account Settings',
              icon: Icons.settings,
              child: Column(
                children: [  
                  ModernDropdownFormField<String>(
                    value: _selectedRole,
                    labelText: 'User Role',
                    prefixIcon: Icons.badge,
                    items: const [
                      DropdownMenuItem(
                          value: 'counselor', child: Text('Counselor')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ModernTextFormField(
                    controller: _passwordController,
                    labelText: 'Password',
                    hintText: 'Enter a secure password',
                    prefixIcon: Icons.lock,
                    obscureText: !_showPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter a password'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  ModernTextFormField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter the password',
                    prefixIcon: Icons.lock_clock,
                    obscureText: !_showConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _showConfirmPassword = !_showConfirmPassword;
                        });
                      },
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
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      actions: [
        const ModernActionButton(
          text: 'Cancel',
        ),
        ModernActionButton(
          text: 'Add User',
          isPrimary: true,
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      // For admin-created accounts, we'll create them and then manually confirm them
                      final authResponse =
                          await Supabase.instance.client.auth.signUp(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                      );

                      if (authResponse.user != null) {
                        // Insert user data into users table
                        await Supabase.instance.client.from('users').insert({
                          'user_id': authResponse.user!.id,
                          'email': _emailController.text.trim(),
                          'user_type': _selectedRole,
                          'status': 'active',
                          'registration_date':
                              DateTime.now().toIso8601String(),
                        });

                        // Store values before clearing controllers
                        final createdEmail = _emailController.text.trim();
                        final createdPassword = _passwordController.text;
                        final createdRole = _selectedRole;

                        if (mounted) {
                          Navigator.pop(context);
                          
                          // Show clean success dialog with account details
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'User Created Successfully!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF3A3A50),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Account Details',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: const Color(0xFF3A3A50),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildDetailRow('Email', createdEmail),
                                        const SizedBox(height: 8),
                                        _buildDetailRow('Password', createdPassword),
                                        const SizedBox(height: 8),
                                        _buildDetailRow('Role', createdRole.toUpperCase()),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'An email verification has been sent to the user. They must verify before logging in.',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.orange.shade700,
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
                                      backgroundColor: const Color(0xFF7C83FD),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Got it',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          
                          _loadUsers();
                        }
                      }
                    } catch (e) {
                      print('Error creating user: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to create user')),
                        );
                      }
                    } finally {
                      setState(() {
                        _isLoading = false;
                        _emailController.clear();
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                        _selectedRole = 'counselor';
                        _showPassword = false;
                        _showConfirmPassword = false;
                      });
                    }
                  }
                },
          isLoading: _isLoading,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        title: Text(
          "User Management",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3A3A50),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search users...",
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) => _applyFilters(),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Users'),
                      _buildFilterChip('student', 'Students'),
                      _buildFilterChip('counselor', 'Counselors'),
                      _buildFilterChip('admin', 'Admins'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          'No users found',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isActive = user['status'] == 'active';
                          final studentData = user['students'] is List
                              ? (user['students'] as List).isNotEmpty
                                  ? user['students'][0] as Map<String, dynamic>
                                  : null
                              : user['students'] as Map<String, dynamic>?;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor:
                                    _getUserTypeColor(user['user_type'])
                                        .withOpacity(0.1),
                                child: Icon(
                                  _getUserTypeIcon(user['user_type']),
                                  color: _getUserTypeColor(user['user_type']),
                                ),
                              ),
                              title: Text(
                                user['email'] ?? 'No Email',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    user['email'] ?? 'No Email',
                                    style: GoogleFonts.poppins(
                                        color: Colors.grey[600]),
                                  ),
                                  if (studentData != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Student ID: ${studentData['student_code'] ?? 'N/A'}',
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey[600]),
                                    ),
                                    if (studentData['course'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Course: ${studentData['course']}',
                                        style: GoogleFonts.poppins(
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getUserTypeColor(
                                                  user['user_type'])
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          (user['user_type'] ?? 'unknown')
                                              .toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: _getUserTypeColor(
                                                user['user_type']),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isActive ? 'ACTIVE' : 'SUSPENDED',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isActive
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'toggle_status',
                                    child: Text(
                                      isActive
                                          ? 'Suspend User'
                                          : 'Activate User',
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete User'),
                                  ),
                                ],
                                onSelected: (value) async {
                                  if (value == 'toggle_status') {
                                    await _toggleUserStatus(
                                      user['user_id'],
                                      user['status'],
                                    );
                                  } else if (value == 'delete') {
                                    await _deleteUserWithRelatedData(user['user_id']);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: const Color(0xFF7C83FD),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
            _applyFilters();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF7C83FD).withOpacity(0.2),
        checkmarkColor: const Color(0xFF7C83FD),
        labelStyle: GoogleFonts.poppins(
          color: isSelected ? const Color(0xFF7C83FD) : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A3A50),
            ),
          ),
        ),
      ],
    );
  }

  Color _getUserTypeColor(String? userType) {
    switch (userType) {
      case 'admin':
        return const Color(0xFF7C83FD);
      case 'counselor':
        return const Color(0xFF81C784);
      case 'student':
        return const Color(0xFF4F646F);
      default:
        return Colors.grey;
    }
  }

  IconData _getUserTypeIcon(String? userType) {
    switch (userType) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'counselor':
        return Icons.psychology;
      case 'student':
        return Icons.school;
      default:
        return Icons.person;
    }
  }
}
