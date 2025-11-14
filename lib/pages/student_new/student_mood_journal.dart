import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../controllers/student_mood_journal_controller.dart';
import '../../services/intervention_service.dart';

class StudentMoodJournal extends StatefulWidget {
  const StudentMoodJournal({super.key});

  @override
  State<StudentMoodJournal> createState() => _StudentMoodJournalState();
}

class _StudentMoodJournalState extends State<StudentMoodJournal> {
  final StudentMoodJournalController _controller = StudentMoodJournalController();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSharedWithCounselor = false;

  Future<void> _submitJournal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await _controller.submitJournal(
        title: _titleController.text,
        content: _contentController.text,
        isSharedWithCounselor: _isSharedWithCounselor,
      );

      if (result.success) {
        // Clear form first
        _titleController.clear();
        _contentController.clear();
        setState(() {
          _isSharedWithCounselor = false;
        });

        // Show high-risk modal if needed (before success dialog)
        if (result.interventionLevel == InterventionLevel.high &&
            result.hotlines != null &&
            result.hotlines!.isNotEmpty &&
            mounted) {
          await _showHighRiskModal(result.hotlines!);
        }

        // Show success dialog
        if (mounted) {
          await _showAlertDialog(
            'Success',
            'Journal entry saved successfully',
            Icons.check_circle_outline,
            Colors.green,
          );
        }

        // Navigate back after dialog is dismissed
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          _showAlertDialog(
            'Error',
            result.errorMessage ?? 'Error saving journal entry',
            Icons.error_outline,
            Colors.red,
          );
        }
      }
    } catch (e) {
      print('Error submitting journal: $e');
      if (mounted) {
        _showAlertDialog(
          'Error',
          'An unexpected error occurred',
          Icons.error_outline,
          Colors.red,
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showAlertDialog(
      String title, String message, IconData icon, Color color) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
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
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
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
    );
  }

  Future<void> _showHighRiskModal(List<Map<String, dynamic>> hotlines) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C83FD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.support_agent,
                          color: Color(0xFF7C83FD),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'We are here for you',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'If things feel overwhelming, please reach out now. You can contact your counselor or call a hotline:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF5D5D72),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Hotlines list
                  ...hotlines.map((h) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C83FD).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF7C83FD).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C83FD).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.call,
                              size: 20,
                              color: Color(0xFF7C83FD),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h['name'] ?? 'Hotline',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: const Color(0xFF3A3A50),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  h['phone'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF7C83FD),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if ((h['city_or_region'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    h['city_or_region'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF5D5D72),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF7C83FD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF7C83FD),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.pushNamed(context, 'student-counselors');
                  },
                  child: Text(
                    'Contact Counselor',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pastelBlue = Color.fromARGB(255, 242, 241, 248);
    const darkText = Color(0xFF3A3A50);

    return Scaffold(
      backgroundColor: pastelBlue,
      appBar: AppBar(
        backgroundColor: pastelBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF5D5D72)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Write Journal Entry",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
        actions: const [
          StudentNotificationButton(),
        ],
      ),
      drawer: const StudentDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 0),

                // Title input
                TextFormField(
                  key: const Key('journal_title_field'),
                  controller: _titleController,
                  style: GoogleFonts.poppins(fontSize: 16, color: darkText),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: GoogleFonts.poppins(color: darkText),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 255, 255, 255),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: _controller.validateTitle,
                ),
                const SizedBox(height: 16),

                // Content input
                Expanded(
                  child: TextFormField(
                    key: const Key('journal_content_field'),
                    controller: _contentController,
                    style: GoogleFonts.poppins(fontSize: 15, color: darkText),
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: GoogleFonts.poppins(
                        color: darkText.withOpacity(0.7),
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 255, 255, 255),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: null,
                    expands: true,
                    validator: _controller.validateContent,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
                const SizedBox(height: 16),

                // Switch for counselor sharing
                SwitchListTile(
                  title: Text(
                    'Share with counselor',
                    style: GoogleFonts.poppins(fontSize: 15, color: darkText),
                  ),
                  activeColor: const Color(0xFF7C83FD),
                  value: _isSharedWithCounselor,
                  onChanged: (value) {
                    setState(() {
                      _isSharedWithCounselor = value;
                    });
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                const SizedBox(height: 16),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitJournal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C83FD),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      key: const Key('save_journal_entry_button'),
                      _isSubmitting ? 'Saving...' : 'Save Entry',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
