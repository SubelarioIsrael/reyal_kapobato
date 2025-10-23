import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/modern_form_dialog.dart';

class AdminQuestionnaire extends StatefulWidget {
  const AdminQuestionnaire({super.key});

  @override
  State<AdminQuestionnaire> createState() => _AdminQuestionnaireState();
}

class _AdminQuestionnaireState extends State<AdminQuestionnaire> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _filteredQuestions = [];
  List<Map<String, dynamic>> _versions = [];
  int _selectedVersionId = 0;
  String _selectedCategory = 'PHQ-9';

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadVersions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final versionsResponse = await Supabase.instance.client
          .from('questionnaire_versions')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _versions = List<Map<String, dynamic>>.from(versionsResponse);
        if (_versions.isNotEmpty) {
          _selectedVersionId = _versions[0]['version_id'] as int;
          _loadQuestions();
        }
      });
    } catch (e) {
      print('Error loading versions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to load questionnaire versions')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadQuestions() async {
    if (_selectedVersionId == 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('questionnaire_questions')
          .select('''
            question_id,
            question_order,
            questions:question_id (
              question_id,
              question_text,
              category,
              is_active,
              created_at
            )
          ''')
          .eq('version_id', _selectedVersionId)
          .order('question_order');

      setState(() {
        _questions = List<Map<String, dynamic>>.from(response)
            .map((q) => q['questions'] as Map<String, dynamic>)
            .toList();
        _filteredQuestions = _questions;
      });
    } catch (e) {
      print('Error loading questions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load questions')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showEditQuestionDialog(Map<String, dynamic> question) {
    _questionController.text = question['question_text'];
    
    ModernFormDialog.show(
      context: context,
      title: 'Edit Question',
      subtitle: 'Modify the selected question text',
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormSection(
              title: 'Question Details',
              icon: Icons.edit_outlined,
              child: ModernTextFormField(
                controller: _questionController,
                labelText: 'Question Text',
                hintText: 'Enter the updated question text',
                prefixIcon: Icons.help_outline,
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a question' : null,
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
          text: 'Update Question',
          isPrimary: true,
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      await Supabase.instance.client
                          .from('questions')
                          .update({
                        'question_text': _questionController.text.trim(),
                      }).eq('question_id', question['question_id']);

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Question updated successfully')),
                        );
                        _loadQuestions();
                      }
                    } catch (e) {
                      print('Error updating question: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Failed to update question')),
                        );
                      }
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
          isLoading: _isLoading,
        ),
      ],
    );
  }

  void _showAddQuestionDialog() {
    _questionController.clear();
    _selectedCategory = 'PHQ-9';
    
    ModernFormDialog.show(
      context: context,
      title: 'Add New Question',
      subtitle: 'Create a new question for the questionnaire',
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormSection(
              title: 'Question Details',
              icon: Icons.quiz_outlined,
              child: Column(
                children: [
                  ModernTextFormField(
                    controller: _questionController,
                    labelText: 'Question Text',
                    hintText: 'Enter the question text that will be displayed to users',
                    prefixIcon: Icons.help_outline,
                    maxLines: 3,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter a question' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'PHQ-9', child: Text('PHQ-9')),
                      DropdownMenuItem(value: 'GAD-7', child: Text('GAD-7')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value ?? 'PHQ-9';
                      });
                    },
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please select a category' : null,
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
          text: 'Add Question',
          isPrimary: true,
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      final questionResponse = await Supabase.instance.client
                          .from('questions')
                          .insert({
                            'question_text': _questionController.text.trim(),
                            'category': _selectedCategory,
                            'is_active': true,
                          })
                          .select()
                          .single();

                      await Supabase.instance.client
                          .from('questionnaire_questions')
                          .insert({
                        'version_id': _selectedVersionId,
                        'question_id': questionResponse['question_id'],
                        'question_order': _questions.length + 1,
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Question added successfully')),
                        );
                        _loadQuestions();
                      }
                    } catch (e) {
                      print('Error adding question: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Failed to add question')),
                        );
                      }
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
          isLoading: _isLoading,
        ),
      ],
    );
  }

  void _showCreateVersionDialog() {
    final versionController = TextEditingController();
    
    ModernFormDialog.show(
      context: context,
      title: 'Create New Version',
      subtitle: 'Create a new questionnaire version with optional question copying',
      content: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormSection(
              title: 'Version Information',
              icon: Icons.new_releases_outlined,
              child: ModernTextFormField(
                controller: versionController,
                labelText: 'Version Name',
                hintText: 'e.g., Student Mental Health Questionnaire v2',
                prefixIcon: Icons.label_outline,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a version name' : null,
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
          text: 'Create Version',
          isPrimary: true,
          onPressed: () async {
            if (versionController.text.trim().isNotEmpty) {
              // Check for duplicate version name
              final trimmedVersionName = versionController.text.trim();
              final duplicateVersion = _versions.firstWhere(
                (v) => (v['version_name'] as String).toLowerCase() == 
                       trimmedVersionName.toLowerCase(),
                orElse: () => {},
              );

              if (duplicateVersion.isNotEmpty) {
                // Show popup warning dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Duplicate Version Name',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A version with this name already exists. Please choose a different name.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Existing: "$trimmedVersionName"',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
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
                            'OK',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                return;
              }

              try {
                // Create new version
                final versionResponse = await Supabase.instance.client
                    .from('questionnaire_versions')
                    .insert({
                      'version_name': trimmedVersionName,
                      'is_active': true,
                    })
                    .select()
                    .single();

                // Copy questions from current version to new version
                if (_selectedVersionId != 0) {
                  final questions = await Supabase.instance.client
                      .from('questionnaire_questions')
                      .select()
                      .eq('version_id', _selectedVersionId);

                  for (var question in questions) {
                    await Supabase.instance.client
                        .from('questionnaire_questions')
                        .insert({
                      'version_id': versionResponse['version_id'],
                      'question_id': question['question_id'],
                      'question_order': question['question_order'],
                    });
                  }
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('New version created successfully')),
                  );
                  _loadVersions();
                }
              } catch (e) {
                print('Error creating version: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Failed to create new version')),
                  );
                }
              }
            }
          },
        ),
      ],
    );
  }

  Future<void> _toggleVersionStatus(int versionId, bool currentStatus) async {
    try {
      // If trying to deactivate, check if there are other active versions
      if (currentStatus) {
        final activeVersionsResponse = await Supabase.instance.client
            .from('questionnaire_versions')
            .select('version_id')
            .eq('is_active', true);

        final activeVersions = List<Map<String, dynamic>>.from(activeVersionsResponse);
        
        // If this is the only active version, prevent deactivation
        if (activeVersions.length <= 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot deactivate the last active version. At least one version must remain active.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // First, deactivate all versions
      await Supabase.instance.client
          .from('questionnaire_versions')
          .update({'is_active': false}).neq('version_id', versionId);

      // Then, set the selected version's status
      await Supabase.instance.client
          .from('questionnaire_versions')
          .update({'is_active': !currentStatus}).eq('version_id', versionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Version ${!currentStatus ? 'activated' : 'deactivated'} successfully'),
          ),
        );
        _loadVersions();
      }
    } catch (e) {
      print('Error updating version status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update version status')),
        );
      }
    }
  }

  Future<void> _deleteQuestion(int questionId) async {
    try {
      // First delete related answers
      await Supabase.instance.client
          .from('questionnaire_answers')
          .delete()
          .eq('question_id', questionId);

      // Then remove from questionnaire_questions
      await Supabase.instance.client
          .from('questionnaire_questions')
          .delete()
          .eq('question_id', questionId)
          .eq('version_id', _selectedVersionId);

      // Finally delete the question itself
      await Supabase.instance.client
          .from('questions')
          .delete()
          .eq('question_id', questionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question deleted successfully')),
        );
        _loadQuestions();
      }
    } catch (e) {
      print('Error deleting question: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete question')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedVersion = _versions.firstWhere(
      (v) => v['version_id'] == _selectedVersionId,
      orElse: () => {'is_active': false},
    );
    final isVersionActive = selectedVersion['is_active'] as bool? ?? false;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        title: Text(
          "MTQ Management",
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: _selectedVersionId,
                        decoration: const InputDecoration(
                          labelText: 'Select Version',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        isExpanded: true,
                        items: _versions.map((version) {
                          return DropdownMenuItem<int>(
                            value: version['version_id'] as int,
                            child: Text(
                              version['version_name'] as String,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedVersionId = value;
                            });
                            _loadQuestions();
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showCreateVersionDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('New Version'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C83FD),
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _toggleVersionStatus(
                                _selectedVersionId, isVersionActive),
                            icon: Icon(isVersionActive
                                ? Icons.toggle_off
                                : Icons.toggle_on),
                            label: Text(
                                isVersionActive ? 'Deactivate' : 'Activate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isVersionActive ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredQuestions.isEmpty
                      ? Center(
                          child: Text(
                            'No questions found',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredQuestions.length,
                          itemBuilder: (context, index) {
                            final question = _filteredQuestions[index];

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
                                title: Text(
                                  question['question_text'] ??
                                      'No Question Text',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF3A3A50),
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: question['category'] == 'PHQ-9'
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      question['category'] ?? 'No Category',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: question['category'] == 'PHQ-9'
                                            ? Colors.blue[700]
                                            : Colors.green[700],
                                      ),
                                    ),
                                  ),
                                ),
                                trailing: PopupMenuButton<String>(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit Question'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete Question'),
                                    ),
                                  ],
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      _showEditQuestionDialog(question);
                                    } else if (value == 'delete') {
                                      await _deleteQuestion(
                                          question['question_id']);
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
        onPressed: _showAddQuestionDialog,
        backgroundColor: const Color(0xFF7C83FD),
        child: const Icon(Icons.add),
      ),
    );
  }
}
