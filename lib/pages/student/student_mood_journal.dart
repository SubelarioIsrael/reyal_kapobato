import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../services/activity_service.dart';
import '../../services/api/sentiment_app.dart'; // Ensure this import is present
import '../../services/intervention_service.dart';

class StudentMoodJournal extends StatefulWidget {
  const StudentMoodJournal({super.key});

  @override
  State<StudentMoodJournal> createState() => _StudentMoodJournalState();
}

class _StudentMoodJournalState extends State<StudentMoodJournal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSharedWithCounselor = false;
  List<Map<String, dynamic>> _hotlines = const [];

  Future<void> _submitJournal() async {
    final result = await analyzeSentiment(_contentController.text.trim());
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Not logged in.")));
      return;
    }

    try {
      final inserted = await Supabase.instance.client
          .from('journal_entries')
          .insert({
            // Title is optional; include only when provided
            if (_titleController.text.trim().isNotEmpty)
              'title': _titleController.text.trim(),
            'content': _contentController.text.trim(),
            'sentiment': result['sentiment'],
            'insight': result['thought'],
            'entry_timestamp': DateTime.now().toIso8601String(),
            'is_shared_with_counselor': _isSharedWithCounselor,
            'user_id': userId,
          })
          .select('journal_id')
          .single();

      final int journalId = inserted['journal_id'] as int;

      final level = await InterventionService.triggerJournalIntervention(
        journalId: journalId,
        userId: userId,
        sentiment: (result['sentiment'] ?? '').toString(),
        content: _contentController.text.trim(),
        insight: (result['thought'] ?? '').toString(),
      );

      if (level == InterventionLevel.high) {
        _hotlines = await InterventionService.fetchHotlines(limit: 5);
        if (mounted) _showHighRiskModal();
      }

      // Record activity completion
      await ActivityService.recordActivityCompletion('mood_journal');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Journal entry saved.")));
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _isSharedWithCounselor = false;
      });
      Navigator.of(context).pop();
    } catch (e) {
      print("Insert error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error saving entry.")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const pastelBlue = Color.fromARGB(255, 242, 241, 248);
    // const lightPurple = Color.fromARGB(255, 244, 253, 231);
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
          "BreatheBetter",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
        actions: [
          const StudentNotificationButton(),
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
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter a title'
                      : null,
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
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Speak your mind'
                            : null,
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
                // Realtime toasts could be added in a separate listener screen-wide
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHighRiskModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Text('We are here for you', style: GoogleFonts.poppins()),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'If things feel overwhelming, please reach out now. You can contact your counselor or call a hotline:',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                const SizedBox(height: 12),
                ..._hotlines.map((h) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.call,
                              size: 16, color: Color(0xFF7C83FD)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h['name'] ?? 'Hotline',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600)),
                                Text(h['phone'] ?? '',
                                    style: GoogleFonts.poppins(fontSize: 12)),
                                if ((h['city_or_region'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(h['city_or_region'],
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, 'student-counselors');
              },
              child: Text('Contact counselor',
                  style: GoogleFonts.poppins(color: const Color(0xFF7C83FD))),
            ),
          ],
        );
      },
    );
  }
}
