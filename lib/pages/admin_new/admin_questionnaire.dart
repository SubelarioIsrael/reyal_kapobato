import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/admin_questionnaire_controller.dart';

class AdminQuestionnaire extends StatefulWidget {
  const AdminQuestionnaire({super.key});

  @override
  State<AdminQuestionnaire> createState() => _AdminQuestionnaireState();
}

class _AdminQuestionnaireState extends State<AdminQuestionnaire> {
  final _controller = AdminQuestionnaireController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _versions = [];
  int _selectedVersionId = 0;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _controller.loadVersions();

    if (result.success) {
      setState(() {
        _versions = result.versions;
        if (_versions.isNotEmpty) {
          _selectedVersionId = result.activeVersionId ?? _versions[0]['version_id'] as int;
        }
      });
      if (_selectedVersionId != 0) {
        _loadQuestions();
      }
    } else {
      _showErrorDialog(result.errorMessage ?? 'Failed to load versions');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadQuestions() async {
    if (_selectedVersionId == 0) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _controller.loadQuestions(_selectedVersionId);

    if (result.success) {
      setState(() {
        _questions = result.questions;
      });
    } else {
      _showErrorDialog(result.errorMessage ?? 'Failed to load questions');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showAddQuestionModal() {
    final questionController = TextEditingController();
    String selectedCategory = 'PHQ-9';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
                        Icons.quiz_outlined,
                        color: Color(0xFF7C83FD),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Question',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a new question for the questionnaire',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF5D5D72),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF3A3A50)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: questionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Question Text',
                            hintText: 'Enter the question text that will be displayed to users',
                            prefixIcon: const Icon(Icons.help_outline, color: Color(0xFF7C83FD)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                            ),
                          ),
                          validator: _controller.validateQuestionText,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF7C83FD)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'PHQ-9', child: Text('PHQ-9')),
                            DropdownMenuItem(value: 'GAD-7', child: Text('GAD-7')),
                          ],
                          onChanged: (value) {
                            setModalState(() {
                              selectedCategory = value ?? 'PHQ-9';
                            });
                          },
                          validator: _controller.validateCategory,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                setState(() {
                                  _isLoading = true;
                                });

                                final result = await _controller.createQuestion(
                                  questionText: questionController.text,
                                  category: selectedCategory,
                                  versionId: _selectedVersionId,
                                  questionOrder: _questions.length + 1,
                                );

                                setState(() {
                                  _isLoading = false;
                                });

                                if (result.success) {
                                  Navigator.pop(context);
                                  _showSuccessDialog('Question added successfully');
                                  _loadQuestions();
                                } else {
                                  _showErrorDialog(result.errorMessage ?? 'Failed to add question');
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C83FD),
                              foregroundColor: Colors.white,
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
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Add Question',
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditQuestionModal(Map<String, dynamic> question) {
    final questionController = TextEditingController(text: question['question_text']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                      Icons.edit_outlined,
                      color: Color(0xFF7C83FD),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Question',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Modify the selected question text',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF5D5D72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF3A3A50)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: questionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Question Text',
                          hintText: 'Enter the updated question text',
                          prefixIcon: const Icon(Icons.help_outline, color: Color(0xFF7C83FD)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                          ),
                        ),
                        validator: _controller.validateQuestionText,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              setState(() {
                                _isLoading = true;
                              });

                              final result = await _controller.updateQuestion(
                                questionId: question['question_id'],
                                questionText: questionController.text,
                              );

                              setState(() {
                                _isLoading = false;
                              });

                              if (result.success) {
                                Navigator.pop(context);
                                _showSuccessDialog('Question updated successfully');
                                _loadQuestions();
                              } else {
                                _showErrorDialog(result.errorMessage ?? 'Failed to update question');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C83FD),
                            foregroundColor: Colors.white,
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
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Update Question',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateVersionModal() {
    final versionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                      Icons.new_releases_outlined,
                      color: Color(0xFF7C83FD),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Version',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a new questionnaire version with optional question copying',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF5D5D72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF3A3A50)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: versionController,
                        decoration: InputDecoration(
                          labelText: 'Version Name',
                          hintText: 'e.g., Student Mental Health Questionnaire v2',
                          prefixIcon: const Icon(Icons.label_outline, color: Color(0xFF7C83FD)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                          ),
                        ),
                        validator: _controller.validateVersionName,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              setState(() {
                                _isLoading = true;
                              });

                              final result = await _controller.createVersion(
                                versionName: versionController.text,
                                existingVersions: _versions,
                              );

                              setState(() {
                                _isLoading = false;
                              });

                              if (result.success) {
                                Navigator.pop(context);
                                _showSuccessDialog('New version created successfully');
                                _loadVersions();
                              } else {
                                if (result.errorType == 'duplicate') {
                                  _showDuplicateVersionDialog(versionController.text.trim());
                                } else {
                                  _showErrorDialog(result.errorMessage ?? 'Failed to create version');
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C83FD),
                            foregroundColor: Colors.white,
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
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Create Version',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteQuestion(int questionId) async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _controller.deleteQuestion(questionId, _selectedVersionId);

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      _showSuccessDialog('Question deleted successfully');
      _loadQuestions();
    } else {
      _showErrorDialog(result.errorMessage ?? 'Failed to delete question');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.error_outline, color: Colors.red, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Success',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDuplicateVersionDialog(String versionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Duplicate Version Name',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A version with this name already exists. Please choose a different name.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Existing: "$versionName"',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLastActiveVersionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Cannot Deactivate',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is the only active version. At least one version must remain active for students to access the questionnaire.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create and activate another version first before deactivating this one.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Understood',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCannotDeleteActiveVersionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Cannot Delete Active Version',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You cannot delete the currently active version. Please activate another version first.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Switch to another version and activate it before deleting this one.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Understood',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCannotDeleteLastVersionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Cannot Delete Last Version',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is the only version. At least one questionnaire version must exist in the system.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create a new version before deleting this one.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Understood',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteVersionConfirmationDialog(String versionName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Version',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete "$versionName"?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will permanently delete the version and remove all question associations.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3A3A50),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  Future<void> _deleteVersion(int versionId, String versionName) async {
    final confirmed = await _showDeleteVersionConfirmationDialog(versionName);
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _controller.deleteVersion(versionId, _versions);

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      _showSuccessDialog('Version deleted successfully');
      _loadVersions();
    } else {
      if (result.errorType == 'last_version') {
        _showCannotDeleteLastVersionDialog();
      } else if (result.errorType == 'active_version') {
        _showCannotDeleteActiveVersionDialog();
      } else {
        _showErrorDialog(result.errorMessage ?? 'Failed to delete version');
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Question',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete this question from the selected version?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This action will permanently delete the question and all associated answers.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3A3A50),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  List<Widget> _buildQuestionList(String category) {
    final categoryQuestions = _questions
        .asMap()
        .entries
        .where((entry) => entry.value['category'] == category)
        .toList();

    return categoryQuestions.map((entry) {
      final question = entry.value;
      final categoryIndex = categoryQuestions.indexOf(entry);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Question number badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: category == 'PHQ-9'
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${categoryIndex + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: category == 'PHQ-9' ? Colors.blue[700] : Colors.green[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Question content
              Expanded(
                child: Text(
                  question['question_text'] ?? 'No Question Text',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3A3A50),
                    height: 1.4,
                  ),
                ),
              ),
              // Action menu
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF3A3A50),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Color(0xFF7C83FD),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Edit Question',
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
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delete Question',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'edit') {
                    _showEditQuestionModal(question);
                  } else if (value == 'delete') {
                    await _deleteQuestion(question['question_id']);
                  }
                },
              ),
            ],
          ),
        ),
      );
    }).toList();
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
          "Questionnaires",
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Version',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _selectedVersionId,
                                  isExpanded: true,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xFF3A3A50),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Choose a questionnaire version',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  items: _versions.map((version) {
                                    final isActive = version['is_active'] as bool? ?? false;
                                    return DropdownMenuItem<int>(
                                      value: version['version_id'] as int,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              version['version_name'] as String,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                    if (isActive)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          'Active',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ),
                                  ],
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
                        ),
                        const SizedBox(width: 12),
                        // Delete Version Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () {
                              final version = _versions.firstWhere(
                                (v) => v['version_id'] == _selectedVersionId,
                                orElse: () => {},
                              );
                              if (version.isNotEmpty) {
                                _deleteVersion(
                                  _selectedVersionId,
                                  version['version_name'] as String,
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                            ),
                            tooltip: 'Delete Version',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showCreateVersionModal,
                              icon: const Icon(Icons.add_rounded, size: 20),
                              label: Text(
                                'Add Version',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C83FD),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                setState(() {
                                  _isLoading = true;
                                });

                                final result = await _controller.toggleVersionStatus(
                                  _selectedVersionId,
                                  isVersionActive,
                                  _versions,
                                );

                                setState(() {
                                  _isLoading = false;
                                });

                                if (result.success) {
                                  _showSuccessDialog(
                                    'Version ${!isVersionActive ? 'activated' : 'deactivated'} successfully'
                                  );
                                  _loadVersions();
                                } else {
                                  if (result.errorType == 'last_active') {
                                    _showLastActiveVersionDialog();
                                  } else {
                                    _showErrorDialog(result.errorMessage ?? 'Failed to toggle version status');
                                  }
                                }
                              },
                              icon: Icon(
                                isVersionActive
                                    ? Icons.cancel_rounded
                                    : Icons.check_circle_rounded,
                                size: 20,
                              ),
                              label: Text(
                                isVersionActive ? 'Deactivate' : 'Activate',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isVersionActive
                                    ? Colors.red
                                    : Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _questions.isEmpty
                      ? Center(
                          child: Text(
                            'No questions found',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // PHQ-9 Questions Section
                              if (_questions.where((q) => q['category'] == 'PHQ-9').isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.psychology_outlined,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'PHQ-9 Questions',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue[700],
                                              ),
                                            ),
                                            Text(
                                              'Patient Health Questionnaire',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.blue[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${_questions.where((q) => q['category'] == 'PHQ-9').length}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._buildQuestionList('PHQ-9'),
                                const SizedBox(height: 24),
                              ],
                              
                              // GAD-7 Questions Section
                              if (_questions.where((q) => q['category'] == 'GAD-7').isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.favorite_outline,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'GAD-7 Questions',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green[700],
                                              ),
                                            ),
                                            Text(
                                              'Generalized Anxiety Disorder',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.green[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${_questions.where((q) => q['category'] == 'GAD-7').length}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._buildQuestionList('GAD-7'),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuestionModal,
        backgroundColor: const Color(0xFF7C83FD),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
