import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Question',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A3A50),
          ),
        ),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _questionController,
            decoration: const InputDecoration(
              labelText: 'Question Text',
              hintText: 'Enter the question text...',
            ),
            maxLines: 3,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a question' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
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
                : const Text('Update Question'),
          ),
        ],
      ),
    );
  }

  void _showAddQuestionDialog() {
    _questionController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Question',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A3A50),
          ),
        ),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _questionController,
            decoration: const InputDecoration(
              labelText: 'Question Text',
              hintText: 'Enter the question text...',
            ),
            maxLines: 3,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a question' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
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
                        final questionResponse = await Supabase.instance.client
                            .from('questions')
                            .insert({
                              'question_text': _questionController.text.trim(),
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
                : const Text('Add Question'),
          ),
        ],
      ),
    );
  }

  void _showCreateVersionDialog() {
    final versionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create New Version',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A3A50),
          ),
        ),
        content: TextField(
          controller: versionController,
          decoration: const InputDecoration(
            labelText: 'Version Name',
            hintText: 'e.g., Student Mental Health Questionnaire v2',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (versionController.text.trim().isNotEmpty) {
                try {
                  // Create new version
                  final versionResponse = await Supabase.instance.client
                      .from('questionnaire_versions')
                      .insert({
                        'version_name': versionController.text.trim(),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C83FD),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Version'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleVersionStatus(int versionId, bool currentStatus) async {
    try {
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
          "Questionnaire Management",
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedVersionId,
                              decoration: const InputDecoration(
                                labelText: 'Select Version',
                                border: OutlineInputBorder(),
                              ),
                              items: _versions.map((version) {
                                return DropdownMenuItem<int>(
                                  value: version['version_id'] as int,
                                  child:
                                      Text(version['version_name'] as String),
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
                          ),
                        ],
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
