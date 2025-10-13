import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDailyUplifts extends StatefulWidget {
  const AdminDailyUplifts({super.key});

  @override
  State<AdminDailyUplifts> createState() => _AdminDailyUpliftsState();
}

class _AdminDailyUpliftsState extends State<AdminDailyUplifts> {
  final _formKey = GlobalKey<FormState>();
  final _quoteController = TextEditingController();
  final _authorController = TextEditingController();
  
  List<Map<String, dynamic>> uplifts = [];
  bool isLoading = true;
  bool isSubmitting = false;
  Map<String, dynamic>? editingUplift;

  @override
  void initState() {
    super.initState();
    _loadUplifts();
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _loadUplifts() async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('uplifts')
          .select('*')
          .order('created_at', ascending: false);
      
      setState(() {
        uplifts = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading uplifts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitUplift() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);
    try {
      if (editingUplift != null) {
        // Update existing uplift
        await Supabase.instance.client
            .from('uplifts')
            .update({
              'quote': _quoteController.text.trim(),
              'author': _authorController.text.trim(),
            })
            .eq('uplift_id', editingUplift!['uplift_id']);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daily uplift updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new uplift
        await Supabase.instance.client.from('uplifts').insert({
          'quote': _quoteController.text.trim(),
          'author': _authorController.text.trim(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daily uplift added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      _clearForm();
      await _loadUplifts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving uplift: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _deleteUplift(int upliftId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Daily Uplift'),
        content: const Text('Are you sure you want to delete this daily uplift? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client
            .from('uplifts')
            .delete()
            .eq('uplift_id', upliftId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daily uplift deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        await _loadUplifts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting uplift: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editUplift(Map<String, dynamic> uplift) {
    setState(() {
      editingUplift = uplift;
      _quoteController.text = uplift['quote'] ?? '';
      _authorController.text = uplift['author'] ?? '';
    });
  }

  void _clearForm() {
    setState(() {
      editingUplift = null;
      _quoteController.clear();
      _authorController.clear();
    });
  }

  void _showAddUpliftDialog() {
    _clearForm(); // Ensure form is clean for new entry
    showDialog(
      context: context,
      builder: (context) => _buildUpliftFormDialog(),
    );
  }

  void _showEditUpliftDialog(Map<String, dynamic> uplift) {
    _editUplift(uplift);
    showDialog(
      context: context,
      builder: (context) => _buildUpliftFormDialog(),
    );
  }

  Widget _buildUpliftFormDialog() {
    return AlertDialog(
      title: Text(
        editingUplift != null ? 'Edit Daily Uplift' : 'Add New Daily Uplift',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3A3A50),
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _quoteController,
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF3A3A50)),
                decoration: InputDecoration(
                  labelText: 'Motivational Quote',
                  labelStyle: GoogleFonts.poppins(color: const Color(0xFF5D5D72)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a motivational quote';
                  }
                  if (value.trim().length < 10) {
                    return 'Quote must be at least 10 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF3A3A50)),
                decoration: InputDecoration(
                  labelText: 'Author',
                  labelStyle: GoogleFonts.poppins(color: const Color(0xFF5D5D72)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the author name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _clearForm();
            Navigator.pop(context);
          },
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : () async {
            await _submitUplift();
            if (mounted) {
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C83FD),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  editingUplift != null ? 'Update' : 'Add',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5D5D72)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Daily Uplifts',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUpliftDialog(),
        backgroundColor: const Color(0xFF7C83FD),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uplifts List
            Text(
              'Existing Daily Uplifts',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 12),
            
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (uplifts.isEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No daily uplifts yet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first motivational quote above',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: uplifts.length,
                itemBuilder: (context, index) {
                  final uplift = uplifts[index];
                  final createdAt = DateTime.parse(uplift['created_at']);
                  final formattedDate = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'ID: ${uplift['uplift_id']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.cyan.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.cyan.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  uplift['quote'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF3A3A50),
                                    height: 1.4,
                                  ),
                                ),
                                if (uplift['author'] != null && uplift['author'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '— ${uplift['author']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () => _showEditUpliftDialog(uplift),
                                icon: const Icon(Icons.edit, color: Color(0xFF7C83FD)),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                onPressed: () => _deleteUplift(uplift['uplift_id']),
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}