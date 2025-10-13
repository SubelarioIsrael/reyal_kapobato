import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/modern_form_dialog.dart';

class AdminResources extends StatefulWidget {
  const AdminResources({super.key});

  @override
  State<AdminResources> createState() => _AdminResourcesState();
}

class _AdminResourcesState extends State<AdminResources> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';
  bool _isLoading = false;
  List<Map<String, dynamic>> _resources = [];
  List<Map<String, dynamic>> _filteredResources = [];
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  final _tagsController = TextEditingController();
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
    try {
      final response = await Supabase.instance.client
          .from('mental_health_resources')
          .select()
          .order('publish_date', ascending: false);
      setState(() {
        _resources = List<Map<String, dynamic>>.from(response);
        _applyFilters();
      });
    } catch (e) {
      print('Error loading resources: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load resources')),
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

  void _showAddResourceDialog() {
    _titleController.clear();
    _contentController.clear();
    _mediaUrlController.clear();
    _tagsController.clear();
    _selectedType = 'article';
    _selectedDate = DateTime.now();
    
    ModernFormDialog.show(
      context: context,
      title: 'Add New Resource',
      subtitle: 'Create a new mental health resource for students',
      content: StatefulBuilder(
        builder: (context, setState) => Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormSection(
                title: 'Basic Information',
                icon: Icons.info_outline,
                child: Column(
                  children: [
                    ModernTextFormField(
                      controller: _titleController,
                      labelText: 'Resource Title',
                      hintText: 'Enter a descriptive title',
                      prefixIcon: Icons.title,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a title'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    ModernDropdownFormField<String>(
                      value: _selectedType,
                      labelText: 'Resource Type',
                      prefixIcon: Icons.category,
                      items: const [
                        DropdownMenuItem(value: 'article', child: Text('Article')),
                        DropdownMenuItem(value: 'video', child: Text('Video')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FormSection(
                title: 'Content',
                icon: Icons.edit_note,
                child: Column(
                  children: [
                    ModernTextFormField(
                      controller: _contentController,
                      labelText: 'Content Description',
                      hintText: 'Provide a detailed description of the resource',
                      prefixIcon: Icons.description,
                      maxLines: 4,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter content'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    ModernTextFormField(
                      controller: _tagsController,
                      labelText: 'Tags',
                      hintText: 'anxiety, depression, self-care (comma separated)',
                      prefixIcon: Icons.label,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FormSection(
                title: 'Additional Settings',
                icon: Icons.settings,
                child: Column(
                  children: [
                    ModernTextFormField(
                      controller: _mediaUrlController,
                      labelText: 'Media URL (Optional)',
                      hintText: 'Link to video, image, or external resource',
                      prefixIcon: Icons.link,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.date_range,
                          color: const Color(0xFF7C83FD),
                        ),
                        title: Text(
                          'Publish Date',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        subtitle: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.toLocal().toString().split(' ')[0]}'
                              : 'Select publish date',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                      ),
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
          text: 'Add Resource',
          isPrimary: true,
          isLoading: _isLoading,
          icon: Icons.add,
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              setState(() {
                _isLoading = true;
              });
              try {
                await Supabase.instance.client
                    .from('mental_health_resources')
                    .insert({
                  'title': _titleController.text.trim(),
                  'description': _contentController.text.trim(),
                  'resource_type': _selectedType,
                  'media_url': _mediaUrlController.text.trim(),
                  'tags': _tagsController.text.trim(),
                  'publish_date': (_selectedDate ?? DateTime.now())
                      .toIso8601String(),
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text('Resource added successfully'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                  _loadResources();
                }
              } catch (e) {
                print('Error adding resource: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text('Failed to add resource'),
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
            }
          },
        ),
      ],
    );
  }

  void _showEditResourceDialog(Map<String, dynamic> resource) {
    _titleController.text = resource['title'] ?? '';
    _contentController.text = resource['description'] ?? '';
    _mediaUrlController.text = resource['media_url'] ?? '';
    _tagsController.text = resource['tags'] ?? '';
    _selectedType = resource['resource_type'] ?? 'article';
    _selectedDate = resource['publish_date'] != null
        ? DateTime.tryParse(resource['publish_date'].toString())
        : DateTime.now();
        
    ModernFormDialog.show(
      context: context,
      title: 'Edit Resource',
      subtitle: 'Update the selected mental health resource',
      content: StatefulBuilder(
        builder: (context, setState) => Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormSection(
                title: 'Basic Information',
                icon: Icons.info_outline,
                child: Column(
                  children: [
                    ModernTextFormField(
                      controller: _titleController,
                      labelText: 'Resource Title',
                      hintText: 'Enter a descriptive title',
                      prefixIcon: Icons.title,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a title'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    ModernDropdownFormField<String>(
                      value: _selectedType,
                      labelText: 'Resource Type',
                      prefixIcon: Icons.category,
                      items: const [
                        DropdownMenuItem(value: 'article', child: Text('Article')),
                        DropdownMenuItem(value: 'video', child: Text('Video')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FormSection(
                title: 'Content',
                icon: Icons.edit_note,
                child: Column(
                  children: [
                    ModernTextFormField(
                      controller: _contentController,
                      labelText: 'Content Description',
                      hintText: 'Provide a detailed description of the resource',
                      prefixIcon: Icons.description,
                      maxLines: 4,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter content'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    ModernTextFormField(
                      controller: _tagsController,
                      labelText: 'Tags',
                      hintText: 'anxiety, depression, self-care (comma separated)',
                      prefixIcon: Icons.label,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FormSection(
                title: 'Additional Settings',
                icon: Icons.settings,
                child: Column(
                  children: [
                    ModernTextFormField(
                      controller: _mediaUrlController,
                      labelText: 'Media URL (Optional)',
                      hintText: 'Link to video, image, or external resource',
                      prefixIcon: Icons.link,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.date_range,
                          color: const Color(0xFF7C83FD),
                        ),
                        title: Text(
                          'Publish Date',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        subtitle: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.toLocal().toString().split(' ')[0]}'
                              : 'Select publish date',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                      ),
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
            if (_formKey.currentState?.validate() ?? false) {
              setState(() {
                _isLoading = true;
              });
              try {
                await Supabase.instance.client
                    .from('mental_health_resources')
                    .update({
                  'title': _titleController.text.trim(),
                  'description': _contentController.text.trim(),
                  'resource_type': _selectedType,
                  'media_url': _mediaUrlController.text.trim(),
                  'tags': _tagsController.text.trim(),
                  'publish_date': (_selectedDate ?? DateTime.now())
                      .toIso8601String(),
                }).eq('resource_id', resource['resource_id']);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text('Resource updated successfully'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                  _loadResources();
                }
              } catch (e) {
                print('Error updating resource: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text('Failed to update resource'),
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
            }
          },
        ),
      ],
    );
  }

  void _confirmDeleteResource(int resourceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource'),
        content: const Text('Are you sure you want to delete this resource?'),
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
                    .from('mental_health_resources')
                    .delete()
                    .eq('resource_id', resourceId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Resource deleted successfully')),
                  );
                  _loadResources();
                }
              } catch (e) {
                print('Error deleting resource: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete resource')),
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
          'Mental Health Resources',
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
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Icon(
                                resource['resource_type'] == 'video'
                                    ? Icons.ondemand_video
                                    : Icons.article,
                                color: resource['resource_type'] == 'video'
                                    ? Colors.redAccent
                                    : Colors.blueAccent,
                                size: 36,
                              ),
                              title: Text(
                                resource['title'] ?? 'No Title',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  if (resource['tags'] != null &&
                                      resource['tags'].toString().isNotEmpty)
                                    Text(
                                      'Tags: ${resource['tags']}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  if (resource['publish_date'] != null)
                                    Text(
                                      'Published: '
                                      "${DateTime.tryParse(resource['publish_date'].toString())?.toLocal().toString().split(' ')[0] ?? ''}",
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    resource['content'] ?? '',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  if (resource['media_url'] != null &&
                                      resource['media_url']
                                          .toString()
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Media: ${resource['media_url']}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
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
                                        _showEditResourceDialog(resource),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    tooltip: 'Delete',
                                    onPressed: () => _confirmDeleteResource(
                                        resource['resource_id'] as int),
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
        onPressed: _showAddResourceDialog,
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
