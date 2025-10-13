import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../services/activity_service.dart';

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

  Future<void> _submitJournal() async {
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
      await Supabase.instance.client.from('journal_entries').insert({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'sentiment_score': 1.00,
        'entry_timestamp': DateTime.now().toIso8601String(),
        'is_shared_with_counselor': _isSharedWithCounselor,
        'user_id': userId,
      });

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
    const lightPurple = Color.fromARGB(255, 244, 253, 231);
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
                      _isSubmitting ? 'Saving...' : 'Save Entry',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
