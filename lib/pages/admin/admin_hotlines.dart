import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/modern_form_dialog.dart';

class AdminHotlines extends StatefulWidget {
  const AdminHotlines({super.key});

  @override
  State<AdminHotlines> createState() => _AdminHotlinesState();
}

class _AdminHotlinesState extends State<AdminHotlines> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _hotlines = [];
  List<Map<String, dynamic>> _filteredHotlines = [];

  @override
  void initState() {
    super.initState();
    _loadHotlines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _regionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadHotlines() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await Supabase.instance.client
          .from('mental_health_hotlines')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _hotlines = List<Map<String, dynamic>>.from(response);
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load hotlines')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHotlines = _hotlines.where((h) {
        if (query.isEmpty) return true;
        final name = (h['name'] ?? '').toString().toLowerCase();
        final phone = (h['phone'] ?? '').toString().toLowerCase();
        final region = (h['city_or_region'] ?? '').toString().toLowerCase();
        final notes = (h['notes'] ?? '').toString().toLowerCase();
        return name.contains(query) ||
            phone.contains(query) ||
            region.contains(query) ||
            notes.contains(query);
      }).toList();
    });
  }

  void _clearFormControllers() {
    _nameController.clear();
    _phoneController.clear();
    _regionController.clear();
    _notesController.clear();
  }

  void _showAddHotlineDialog() {
    _clearFormControllers();
    ModernFormDialog.show(
      context: context,
      title: 'Add Mental Health Hotline',
      subtitle: 'Create a new crisis support hotline for students',
      content: StatefulBuilder(
        builder: (context, setState) => Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormSection(
                title: 'Service Information',
                icon: Icons.support_agent,
                child: Column(
                  children: [
                    ModernTextFormField(
                      controller: _nameController,
                      labelText: 'Service Name',
                      hintText: 'e.g., National Suicide Prevention Lifeline',
                      prefixIcon: Icons.business_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter a service name'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    ModernTextFormField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      hintText: 'e.g., 988 or (555) 123-4567',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter a phone number'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FormSection(
                title: 'Location & Details',
                icon: Icons.info_outline,
                child: Column(
                  children: [
                    ModernTextFormField(
                      controller: _regionController,
                      labelText: 'City/Region (Optional)',
                      hintText: 'Service area or location',
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 20),
                    ModernTextFormField(
                      controller: _notesController,
                      labelText: 'Additional Notes (Optional)',
                      hintText: 'Operating hours, specializations, or other details',
                      prefixIcon: Icons.sticky_note_2_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      actions: [
        ModernActionButton(
          text: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        ModernActionButton(
          text: 'Add Hotline',
          isPrimary: true,
          isLoading: _isLoading,
          icon: Icons.add,
          onPressed: () async {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            setState(() {
              _isLoading = true;
            });
            try {
              await Supabase.instance.client
                  .from('mental_health_hotlines')
                  .insert({
                'name': _nameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'city_or_region': _regionController.text.trim(),
                'notes': _notesController.text.trim(),
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text('Hotline added successfully'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
                _loadHotlines();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text('Failed to add hotline'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            } finally {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      ],
    );
  }

  void _showEditHotlineDialog(Map<String, dynamic> hotline) {
    _nameController.text = hotline['name'] ?? '';
    _phoneController.text = hotline['phone'] ?? '';
    _regionController.text = hotline['city_or_region'] ?? '';
    _notesController.text = hotline['notes'] ?? '';
    ModernFormDialog.show(
      context: context,
      title: 'Edit Mental Health Hotline',
      subtitle: 'Update the selected crisis support hotline',
      content: StatefulBuilder(
        builder: (context, setState) => Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormSection(
                title: 'Service Information',
                icon: Icons.support_agent,
                child: Column(
                  children: [
                    ModernTextFormField(
                      controller: _nameController,
                      labelText: 'Service Name',
                      hintText: 'e.g., National Suicide Prevention Lifeline',
                      prefixIcon: Icons.business_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter a service name'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    ModernTextFormField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      hintText: 'e.g., 988 or (555) 123-4567',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter a phone number'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FormSection(
                title: 'Location & Details',
                icon: Icons.info_outline,
                child: Column(
                  children: [
                    ModernTextFormField(
                      controller: _regionController,
                      labelText: 'City/Region (Optional)',
                      hintText: 'Service area or location',
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 20),
                    ModernTextFormField(
                      controller: _notesController,
                      labelText: 'Additional Notes (Optional)',
                      hintText: 'Operating hours, specializations, or other details',
                      prefixIcon: Icons.sticky_note_2_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      actions: [
        ModernActionButton(
          text: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        ModernActionButton(
          text: 'Save Changes',
          isPrimary: true,
          isLoading: _isLoading,
          icon: Icons.save,
          onPressed: () async {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            setState(() {
              _isLoading = true;
            });
            try {
              await Supabase.instance.client
                  .from('mental_health_hotlines')
                  .update({
                'name': _nameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'city_or_region': _regionController.text.trim(),
                'notes': _notesController.text.trim(),
              }).eq('hotline_id', hotline['hotline_id']);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text('Hotline updated successfully'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
                _loadHotlines();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text('Failed to update hotline'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            } finally {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      ],
    );
  }

  void _confirmDeleteHotline(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hotline'),
        content: const Text('Are you sure you want to delete this hotline?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });
              try {
                await Supabase.instance.client
                    .from('mental_health_hotlines')
                    .delete()
                    .eq('hotline_id', id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hotline deleted')),
                  );
                  _loadHotlines();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete hotline')),
                  );
                }
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
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
          'Manage Hotlines',
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
                    hintText: 'Search name, phone, or region...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (v) => _applyFilters(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHotlines.isEmpty
                    ? Center(
                        child: Text(
                          'No hotlines found',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredHotlines.length,
                        itemBuilder: (context, index) {
                          final hotline = _filteredHotlines[index];
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
                                    const Color(0xFF4F646F).withOpacity(0.1),
                                child: const Icon(Icons.phone,
                                    color: Color(0xFF4F646F)),
                              ),
                              title: Text(
                                hotline['name'] ?? 'Unknown',
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
                                    hotline['phone'] ?? '',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  if ((hotline['city_or_region'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        hotline['city_or_region'],
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  if ((hotline['notes'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        hotline['notes'],
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Color(0xFF7C83FD)),
                                    tooltip: 'Edit',
                                    onPressed: () =>
                                        _showEditHotlineDialog(hotline),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    tooltip: 'Delete',
                                    onPressed: () => _confirmDeleteHotline(
                                        hotline['hotline_id'] as int),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHotlineDialog,
        backgroundColor: const Color(0xFF7C83FD),
        child: const Icon(Icons.add),
      ),
    );
  }
}
