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
          .inFilter('user_type', ['admin', 'counselor']).order('username');

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Account',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A3A50),
          ),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.work_outline),
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
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a password'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
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
                            const SnackBar(
                              content: Text('Failed to create account'),
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
              backgroundColor: const Color(0xFF7C83FD),
              foregroundColor: Colors.white,
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
                : const Text('Add Account'),
          ),
        ],
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
                                    : const Color(0xFF81C784).withOpacity(0.1),
                                child: Icon(
                                  account['user_type'] == 'admin'
                                      ? Icons.admin_panel_settings
                                      : Icons.psychology,
                                  color: account['user_type'] == 'admin'
                                      ? const Color(0xFF7C83FD)
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
