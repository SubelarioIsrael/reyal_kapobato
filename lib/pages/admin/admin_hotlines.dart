import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:io';

import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../../components/modern_form_dialog.dart';
import '../../widgets/hotline_avatar.dart';
import '../../services/profile_image_service.dart';

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
  
  File? _selectedImage;
  String? _selectedImageBase64; // Store base64 data like counselors and students
  String? _profileImageUrl;

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
    _selectedImage = null;
    _selectedImageBase64 = null; // Clear base64 data too
    _profileImageUrl = null;
  }

  Future<void> _pickImage() async {
    try {
      // Use the same image selection approach as counselors and students
      final String? base64Image = await ProfileImageService.showImageSourceDialog(context);
      if (base64Image != null) {
        // Convert base64 back to File for preview (temporary approach)
        final bytes = base64Decode(base64Image);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_hotline_image.jpg');
        await tempFile.writeAsBytes(bytes);
        
        setState(() {
          _selectedImage = tempFile;
          _selectedImageBase64 = base64Image; // Store the base64 data
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                    // Profile Image Selector
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.photo_camera_outlined,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Profile Picture (Optional)',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Image Preview
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: _selectedImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : _profileImageUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              _profileImageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Icon(Icons.photo, color: Colors.grey[400], size: 40),
                                            ),
                                          )
                                        : Icon(
                                            Icons.photo,
                                            color: Colors.grey[400],
                                            size: 40,
                                          ),
                              ),
                              const SizedBox(width: 16),
                              // Upload Button
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await _pickImage();
                                    setState(() {}); // Refresh dialog
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C83FD).withOpacity(0.1),
                                    foregroundColor: const Color(0xFF7C83FD),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.upload, size: 20),
                                  label: Text(
                                    _selectedImage != null || _profileImageUrl != null
                                        ? 'Change Image'
                                        : 'Select Image',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedImage != null || _profileImageUrl != null) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                  _profileImageUrl = null;
                                });
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: EdgeInsets.zero,
                              ),
                              icon: const Icon(Icons.delete, size: 16),
                              label: Text(
                                'Remove Image',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
              String? profileImageBase64;
              
              // Use base64 image data if selected (same as counselors and students)
              if (_selectedImageBase64 != null) {
                print('Image selected, using base64 data');
                profileImageBase64 = _selectedImageBase64;
                print('Base64 data length: ${profileImageBase64!.length}');
              }
              
              print('Inserting hotline with data: ${{
                'name': _nameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'city_or_region': _regionController.text.trim(),
                'notes': _notesController.text.trim(),
                'profile_picture': profileImageBase64,
              }}');
              
              final insertResponse = await Supabase.instance.client
                  .from('mental_health_hotlines')
                  .insert({
                'name': _nameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'city_or_region': _regionController.text.trim(),
                'notes': _notesController.text.trim(),
                'profile_picture': profileImageBase64,
              });
              
              print('Database insert response: $insertResponse');
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
    _selectedImage = null;
    _selectedImageBase64 = null; // Clear any new selection
    _profileImageUrl = hotline['profile_picture']; // This is now base64 data
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
                    // Profile Image Selector
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.photo_camera_outlined,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Profile Picture (Optional)',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Image Preview
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: _selectedImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : _profileImageUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              _profileImageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Icon(Icons.photo, color: Colors.grey[400], size: 40),
                                            ),
                                          )
                                        : Icon(
                                            Icons.photo,
                                            color: Colors.grey[400],
                                            size: 40,
                                          ),
                              ),
                              const SizedBox(width: 16),
                              // Upload Button
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await _pickImage();
                                    setState(() {}); // Refresh dialog
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C83FD).withOpacity(0.1),
                                    foregroundColor: const Color(0xFF7C83FD),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.upload, size: 20),
                                  label: Text(
                                    _selectedImage != null || _profileImageUrl != null
                                        ? 'Change Image'
                                        : 'Select Image',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedImage != null || _profileImageUrl != null) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                  _profileImageUrl = null;
                                });
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: EdgeInsets.zero,
                              ),
                              icon: const Icon(Icons.delete, size: 16),
                              label: Text(
                                'Remove Image',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
              String? profileImageBase64 = _profileImageUrl;
              
              // Use new base64 image data if selected (same as counselors and students)
              if (_selectedImageBase64 != null) {
                profileImageBase64 = _selectedImageBase64;
                print('Using new base64 image data, length: ${profileImageBase64!.length}');
              }
              
              await Supabase.instance.client
                  .from('mental_health_hotlines')
                  .update({
                'name': _nameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'city_or_region': _regionController.text.trim(),
                'notes': _notesController.text.trim(),
                'profile_picture': profileImageBase64,
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
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3A3A50),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.storage_outlined),
            tooltip: 'Check Database Schema',
            onPressed: _checkDatabaseColumn,
          ),
        ],
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
                              leading: HotlineAvatar(
                                profilePictureUrl: hotline['profile_picture'],
                                size: 60,
                                backgroundColor: const Color(0xFF4F646F).withOpacity(0.1),
                                iconColor: const Color(0xFF4F646F),
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

  Future<void> _checkDatabaseColumn() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Checking database schema...'),
            ],
          ),
        ),
      );

      // Check if the profile_picture column exists using information_schema
      final columns = await Supabase.instance.client
          .from('information_schema.columns')
          .select('column_name')
          .eq('table_name', 'mental_health_hotlines');
      
      Navigator.of(context).pop(); // Close loading dialog

      final hasProfilePicture = columns.any((col) => col['column_name'] == 'profile_picture');
      
      print('Database columns found: ${columns.map((c) => c['column_name']).join(', ')}');
      print('Profile picture column exists: $hasProfilePicture');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasProfilePicture 
            ? '✅ Database column exists!' 
            : '❌ Database column missing! Please run: ALTER TABLE mental_health_hotlines ADD COLUMN profile_picture TEXT;'),
          backgroundColor: hasProfilePicture ? Colors.green : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );

    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      print('Database column check failed: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Database check failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
