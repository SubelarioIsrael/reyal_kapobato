import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/admin_mental_health_resources_controller.dart';

class AdminMentalHealthResources extends StatefulWidget {
  const AdminMentalHealthResources({super.key});

  @override
  State<AdminMentalHealthResources> createState() => _AdminMentalHealthResourcesState();
}

class _AdminMentalHealthResourcesState extends State<AdminMentalHealthResources> {
  final _controller = AdminMentalHealthResourcesController();
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String _selectedFilter = 'all';
  bool _isLoading = false;
  List<Map<String, dynamic>> _resources = [];
  List<Map<String, dynamic>> _filteredResources = [];
  String _selectedType = 'article';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _mediaUrlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _controller.loadResources();

    if (result.success) {
      setState(() {
        _resources = result.resources;
        _applyFilters();
      });
    } else {
      if (mounted) {
        _showErrorDialog(result.errorMessage ?? 'Failed to load resources');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredResources = _resources.where((resource) {
        final matchesType = _selectedFilter == 'all' ||
            (resource['resource_type']?.toLowerCase() == _selectedFilter);
        final search = _searchController.text.toLowerCase();
        final matchesSearch = search.isEmpty ||
            (resource['title']?.toLowerCase().contains(search) ?? false) ||
            (resource['tags']?.toLowerCase().contains(search) ?? false);
        return matchesType && matchesSearch;
      }).toList();
    });
  }

  void _showAddResourceModal() {
    _titleController.clear();
    _contentController.clear();
    _mediaUrlController.clear();
    _tagsController.clear();
    _selectedType = 'article';
    _selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C83FD).withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                            Icons.library_books,
                            color: Color(0xFF7C83FD),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add New Resource',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create a new mental health resource',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF5D5D72),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF5D5D72)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Resource Title',
                                hintText: 'Enter a descriptive title',
                                prefixIcon: const Icon(Icons.title, color: Color(0xFF7C83FD)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              ),
                              style: GoogleFonts.poppins(),
                              validator: _controller.validateTitle,
                            ),
                            const SizedBox(height: 20),
                            // Resource Type Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedType,
                              decoration: InputDecoration(
                                labelText: 'Resource Type',
                                prefixIcon: const Icon(Icons.category, color: Color(0xFF7C83FD)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                              ),
                              style: GoogleFonts.poppins(color: const Color(0xFF3A3A50)),
                              items: const [
                                DropdownMenuItem(value: 'article', child: Text('Article')),
                                DropdownMenuItem(value: 'video', child: Text('Video')),
                              ],
                              onChanged: (value) {
                                setModalState(() {
                                  _selectedType = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            // Description
                            TextFormField(
                              controller: _contentController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: 'Content Description',
                                hintText: 'Provide a detailed description',
                                prefixIcon: const Icon(Icons.description, color: Color(0xFF7C83FD)),
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              ),
                              style: GoogleFonts.poppins(),
                              validator: _controller.validateDescription,
                            ),
                            const SizedBox(height: 20),
                            // Tags
                            TextFormField(
                              controller: _tagsController,
                              decoration: InputDecoration(
                                labelText: 'Tags (Separate using comma)',
                                hintText: 'anxiety, depression, self-care',
                                prefixIcon: const Icon(Icons.label, color: Color(0xFF7C83FD)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              ),
                              style: GoogleFonts.poppins(),
                            ),
                            const SizedBox(height: 20),
                            // Media URL
                            TextFormField(
                              controller: _mediaUrlController,
                              decoration: InputDecoration(
                                labelText: 'Media URL',
                                hintText: 'https://example.com/resource',
                                prefixIcon: const Icon(Icons.link, color: Color(0xFF7C83FD)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              ),
                              style: GoogleFonts.poppins(),
                              keyboardType: TextInputType.url,
                              validator: _controller.validateMediaUrl,
                            ),
                            const SizedBox(height: 20),
                            // Publish Date
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    _selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.date_range, color: Color(0xFF7C83FD)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Publish Date',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedDate != null
                                                ? '${_selectedDate!.toLocal().toString().split(' ')[0]}'
                                                : 'Select publish date',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: const Color(0xFF3A3A50),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(20),
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
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Color(0xFF7C83FD)),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7C83FD),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _handleAddResource(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C83FD),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Add Resource',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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
        },
      ),
    );
  }

  Future<void> _handleAddResource(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _controller.createResource(
      title: _titleController.text,
      description: _contentController.text,
      resourceType: _selectedType,
      mediaUrl: _mediaUrlController.text,
      tags: _tagsController.text,
      publishDate: _selectedDate ?? DateTime.now(),
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.pop(context);

      if (result.success) {
        _showSuccessDialog('Resource added successfully');
        _loadResources();
      } else {
        _showErrorDialog(result.errorMessage ?? 'Failed to add resource');
      }
    }
  }

  void _showEditResourceModal(Map<String, dynamic> resource) {
    _titleController.text = resource['title'] ?? '';
    _contentController.text = resource['description'] ?? '';
    _mediaUrlController.text = resource['media_url'] ?? '';
    _tagsController.text = resource['tags'] ?? '';
    _selectedType = resource['resource_type'] ?? 'article';
    _selectedDate = resource['publish_date'] != null
        ? DateTime.tryParse(resource['publish_date'].toString())
        : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C83FD).withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                            Icons.edit,
                            color: Color(0xFF7C83FD),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Resource',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Update resource information',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF5D5D72),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF5D5D72)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Resource Title',
                                hintText: 'Enter a descriptive title',
                                prefixIcon: const Icon(Icons.title, color: Color(0xFF7C83FD)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              ),
                              style: GoogleFonts.poppins(),
                              validator: _controller.validateTitle,
                            ),
                            const SizedBox(height: 20),
                            // Resource Type Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedType,
                              decoration: InputDecoration(
                                labelText: 'Resource Type',
                                prefixIcon: const Icon(Icons.category, color: Color(0xFF7C83FD)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                              ),
                              style: GoogleFonts.poppins(color: const Color(0xFF3A3A50)),
                              items: const [
                                DropdownMenuItem(value: 'article', child: Text('Article')),
                                DropdownMenuItem(value: 'video', child: Text('Video')),
                              ],
                              onChanged: (value) {
                                setModalState(() {
                                  _selectedType = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            // Description
                            TextFormField(
                              controller: _contentController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: 'Content Description',
                                hintText: 'Provide a detailed description',
                                prefixIcon: const Icon(Icons.description, color: Color(0xFF7C83FD)),
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              ),
                              style: GoogleFonts.poppins(),
                              validator: _controller.validateDescription,
                            ),
                            const SizedBox(height: 20),
                            // Tags
                            TextFormField(
                              controller: _tagsController,
                              decoration: InputDecoration(
                                labelText: 'Tags',
                                hintText: 'anxiety, depression, self-care',
                                prefixIcon: const Icon(Icons.label, color: Color(0xFF7C83FD)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              ),
                              style: GoogleFonts.poppins(),
                            ),
                            const SizedBox(height: 20),
                            // Media URL
                            TextFormField(
                              controller: _mediaUrlController,
                              decoration: InputDecoration(
                                labelText: 'Media URL',
                                hintText: 'https://example.com/resource',
                                prefixIcon: const Icon(Icons.link, color: Color(0xFF7C83FD)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              ),
                              style: GoogleFonts.poppins(),
                              keyboardType: TextInputType.url,
                              validator: _controller.validateMediaUrl,
                            ),
                            const SizedBox(height: 20),
                            // Publish Date
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    _selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.date_range, color: Color(0xFF7C83FD)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Publish Date',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedDate != null
                                                ? '${_selectedDate!.toLocal().toString().split(' ')[0]}'
                                                : 'Select publish date',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: const Color(0xFF3A3A50),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(20),
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
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Color(0xFF7C83FD)),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7C83FD),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading 
                                ? null 
                                : () => _handleUpdateResource(context, resource['resource_id'] as int),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C83FD),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Save Changes',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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
        },
      ),
    );
  }

  Future<void> _handleUpdateResource(BuildContext context, int resourceId) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _controller.updateResource(
      resourceId: resourceId,
      title: _titleController.text,
      description: _contentController.text,
      resourceType: _selectedType,
      mediaUrl: _mediaUrlController.text,
      tags: _tagsController.text,
      publishDate: _selectedDate ?? DateTime.now(),
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.pop(context);

      if (result.success) {
        _showSuccessDialog('Resource updated successfully');
        _loadResources();
      } else {
        _showErrorDialog(result.errorMessage ?? 'Failed to update resource');
      }
    }
  }

  void _confirmDeleteResource(int resourceId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Resource',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete this resource? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleDeleteResource(context, resourceId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeleteResource(BuildContext context, int resourceId) async {
    Navigator.pop(context);

    setState(() {
      _isLoading = true;
    });

    final result = await _controller.deleteResource(resourceId);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (result.success) {
        _showSuccessDialog('Resource deleted successfully');
        _loadResources();
      } else {
        _showErrorDialog(result.errorMessage ?? 'Failed to delete resource');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Error',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Success',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        title: Text(
          'Mental Health Resources',
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
                    hintText: "Search resources...",
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
                      _buildFilterChip('all', 'All Resources'),
                      _buildFilterChip('article', 'Articles'),
                      _buildFilterChip('video', 'Videos'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredResources.isEmpty
                    ? Center(
                        child: Text(
                          'No resources found',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredResources.length,
                        itemBuilder: (context, index) {
                          final resource = _filteredResources[index];
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
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          resource['title'] ?? 'No Title',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: const Color(0xFF3A3A50),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          resource['description'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: resource['resource_type'] == 'video'
                                                    ? const Color(0xFF7C83FD).withOpacity(0.1)
                                                    : const Color(0xFF81C784).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                (resource['resource_type'] ?? 'article').toUpperCase(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: resource['resource_type'] == 'video'
                                                      ? const Color(0xFF7C83FD)
                                                      : const Color(0xFF81C784),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (resource['tags'] != null &&
                                                resource['tags'].toString().isNotEmpty)
                                              Flexible(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    resource['tags'],
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (resource['publish_date'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              'Published: ${DateTime.tryParse(resource['publish_date'].toString())?.toLocal().toString().split(' ')[0] ?? ''}',
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Colors.grey[600],
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditResourceModal(resource);
                                      } else if (value == 'delete') {
                                        _confirmDeleteResource(
                                            resource['resource_id'] as int);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.edit,
                                              color: Color(0xFF7C83FD),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Edit Resource',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: const Color(0xFF3A3A50),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Delete Resource',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: const Color(0xFF3A3A50),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
        onPressed: _showAddResourceModal,
        backgroundColor: const Color(0xFF7C83FD),
        child: const Icon(Icons.add, color: Colors.white),
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
