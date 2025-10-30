import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAccounts extends StatefulWidget {
  const AdminAccounts({super.key});

  @override
  State<AdminAccounts> createState() => _AdminAccountsState();
}

class _AdminAccountsState extends State<AdminAccounts> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'counselor';
  String _selectedFilter = 'all';
  bool _isLoading = false;
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _filteredAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _searchController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .inFilter('user_type', ['admin', 'counselor', 'student']).order('username');

      setState(() {
        _accounts = List<Map<String, dynamic>>.from(response);
        _applyFilters();
      });
    } catch (e) {
      print('Error loading accounts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load accounts')),
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
      _filteredAccounts = _accounts.where((account) {
        final matchesRole =
            _selectedFilter == 'all' || account['user_type'] == _selectedFilter;
        final matchesSearch = _searchController.text.isEmpty ||
            account['username']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            account['email']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());
        return matchesRole && matchesSearch;
      }).toList();
    });
  }

  Future<void> _toggleAccountStatus(String userId, String currentStatus) async {
    try {
      final newStatus = currentStatus == 'active' ? 'suspended' : 'active';
      await Supabase.instance.client
          .from('users')
          .update({'status': newStatus}).eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Account ${newStatus == 'active' ? 'activated' : 'suspended'} successfully'),
          ),
        );
        _loadAccounts(); // Reload the list
      }
    } catch (e) {
      print('Error updating account status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update account status')),
        );
      }
    }
  }

  void _showAddAccountDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                      Icons.person_add,
                      color: Color(0xFF7C83FD),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Add New Account',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF5D5D72)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF3A3A50)),
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'Enter full name',
                          labelStyle: GoogleFonts.poppins(color: const Color(0xFF5D5D72)),
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF7C83FD)),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF3A3A50)),
                        decoration: InputDecoration(
                          labelText: 'Email Address *',
                          hintText: 'example@email.com',
                          labelStyle: GoogleFonts.poppins(color: const Color(0xFF5D5D72)),
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF7C83FD)),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter an email';
                          }
                          final emailRegex = RegExp(
                            r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(value!)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF3A3A50)),
                        decoration: InputDecoration(
                          labelText: 'Role *',
                          labelStyle: GoogleFonts.poppins(color: const Color(0xFF5D5D72)),
                          prefixIcon: const Icon(Icons.work_outline, color: Color(0xFF7C83FD)),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'counselor',
                            child: Text('Counselor'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem(
                            value: 'student',
                            child: Text('Student'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF3A3A50)),
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          hintText: 'Enter password',
                          labelStyle: GoogleFonts.poppins(color: const Color(0xFF5D5D72)),
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7C83FD)),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter a password'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF3A3A50)),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password *',
                          hintText: 'Re-enter password',
                          labelStyle: GoogleFonts.poppins(color: const Color(0xFF5D5D72)),
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7C83FD)),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Account details will be created in the system and the user will receive access credentials.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF5D5D72),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                setState(() {
                                  _isLoading = true;
                                });

                                try {
                                  // Create auth user
                                  final authResponse =
                                      await Supabase.instance.client.auth.signUp(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text.trim(),
                                  );

                                  if (authResponse.user != null) {
                                    // Create user record
                                    await Supabase.instance.client.from('users').insert({
                                      'user_id': authResponse.user!.id,
                                      'username': _nameController.text.trim(),
                                      'email': _emailController.text.trim(),
                                      'user_type': _selectedRole,
                                      'status': 'active',
                                      'registration_date':
                                          DateTime.now().toIso8601String(),
                                    });
                                    if (_selectedRole == 'counselor') {
                                      // Split the full name into first and last name
                                      final nameParts = _nameController.text.trim().split(' ');
                                      final firstName = nameParts.first;
                                      final lastName = nameParts.length > 1 
                                          ? nameParts.sublist(1).join(' ') 
                                          : '';

                                      await Supabase.instance.client
                                          .from('counselors')
                                          .insert({
                                        'first_name': firstName,
                                        'last_name': lastName,
                                        'email': _emailController.text.trim(),
                                        'department_assigned': 'Volunteer',
                                        'availability_status': 'available',
                                        'bio': 'Professional counselor ready to help you.',
                                        'profile_picture': null, // Will be set later if needed
                                        'user_id': authResponse.user!.id,
                                      });
                                    } else if (_selectedRole == 'student') {
                                      // Split the full name into first and last name
                                      final nameParts = _nameController.text.trim().split(' ');
                                      final firstName = nameParts.first;
                                      final lastName = nameParts.length > 1 
                                          ? nameParts.sublist(1).join(' ') 
                                          : '';

                                      // Generate a unique student code
                                      final studentCode = 'STU${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

                                      await Supabase.instance.client
                                          .from('students')
                                          .insert({
                                        'student_code': studentCode,
                                        'course': 'Not Set', // Default course
                                        'year_level': 1, // Default year level
                                        'user_id': authResponse.user!.id,
                                        'first_name': firstName,
                                        'last_name': lastName,
                                        'strand': 'Not Set', // Default strand
                                        'education_level': 'basic_education', // Default education level
                                      });
                                    }

                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Account created successfully'),
                                        ),
                                      );
                                      _loadAccounts(); // Reload the accounts list
                                    }
                                  }
                                } catch (e) {
                                  print('Error creating account: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to create account: ${e.toString()}'),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                } finally {
                                  setState(() {
                                    _isLoading = false;
                                    _emailController.clear();
                                    _nameController.clear();
                                    _passwordController.clear();
                                    _confirmPasswordController.clear();
                                    _selectedRole = 'counselor';
                                  });
                                }
                              }
                            },
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
                              'Add Account',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        title: Text(
          "Manage Accounts",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
                    hintText: "Search accounts...",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                    ),
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
                      _buildFilterChip('all', 'All Accounts'),
                      _buildFilterChip('admin', 'Admins'),
                      _buildFilterChip('counselor', 'Counselors'),
                      _buildFilterChip('student', 'Students'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAccounts.isEmpty
                    ? Center(
                        child: Text(
                          'No accounts found',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredAccounts.length,
                        itemBuilder: (context, index) {
                          final account = _filteredAccounts[index];
                          final isActive = account['status'] == 'active';
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
                                backgroundColor: account['user_type'] == 'admin'
                                    ? const Color(0xFF7C83FD).withOpacity(0.1)
                                    : account['user_type'] == 'student'
                                        ? const Color(0xFFFF9800).withOpacity(0.1)
                                        : const Color(0xFF81C784).withOpacity(0.1),
                                child: Icon(
                                  account['user_type'] == 'admin'
                                      ? Icons.admin_panel_settings
                                      : account['user_type'] == 'student'
                                          ? Icons.school
                                          : Icons.psychology,
                                  color: account['user_type'] == 'admin'
                                      ? const Color(0xFF7C83FD)
                                      : account['user_type'] == 'student'
                                          ? const Color(0xFFFF9800)
                                          : const Color(0xFF81C784),
                                ),
                              ),
                              title: Text(
                                account['username'] != null &&
                                        account['username'].isNotEmpty
                                    ? account['username'][0].toUpperCase() +
                                        account['username'].substring(1)
                                    : 'No Name',
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
                                    account['email'] ?? 'No Email',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: account['user_type'] == 'admin'
                                              ? const Color(0xFF7C83FD)
                                                  .withOpacity(0.1)
                                              : account['user_type'] == 'student'
                                                  ? const Color(0xFFFF9800)
                                                      .withOpacity(0.1)
                                                  : const Color(0xFF81C784)
                                                      .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          (account['user_type'] ?? 'unknown')
                                              .toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                account['user_type'] == 'admin'
                                                    ? const Color(0xFF7C83FD)
                                                    : account['user_type'] == 'student'
                                                        ? const Color(0xFFFF9800)
                                                        : const Color(0xFF81C784),
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
                                          ? 'Suspend Account'
                                          : 'Activate Account',
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete Account'),
                                  ),
                                ],
                                onSelected: (value) async {
                                  if (value == 'toggle_status') {
                                    await _toggleAccountStatus(
                                      account['user_id'],
                                      account['status'],
                                    );
                                  } else if (value == 'delete') {
                                    try {
                                      await Supabase.instance.client
                                          .from('users')
                                          .delete()
                                          .eq('user_id', account['user_id']);
                                      _loadAccounts(); // Reload the list
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Account deleted successfully'),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      print('Error deleting account: $e');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Failed to delete account'),
                                          ),
                                        );
                                      }
                                    }
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
        onPressed: _showAddAccountDialog,
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
}
