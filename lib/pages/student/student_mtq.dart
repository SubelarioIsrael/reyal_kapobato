import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/question.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../services/activity_service.dart';

class StudentMtq extends StatefulWidget {
  const StudentMtq({super.key});
  @override
  State<StudentMtq> createState() => _StudentMtqState();
}

class _StudentMtqState extends State<StudentMtq> {
  List<Question> questions = [];
  int currentQuestionIndex = 0;
  double progress = 0;
  bool isLoading = true;
  bool showIntroduction = true;
  int? currentVersionId;
  
  // Bi-weekly restriction variables
  bool canTakeQuestionnaire = true;
  DateTime? lastSubmissionDate;
  DateTime? nextAvailableDate;

  @override
  void initState() {
    super.initState();
    _checkBiWeeklyRestriction();
  }

  Future<void> _checkBiWeeklyRestriction() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
          canTakeQuestionnaire = false;
        });
        return;
      }

      // Get the user's most recent questionnaire submission
      final lastResponse = await Supabase.instance.client
          .from('questionnaire_responses')
          .select('submission_timestamp')
          .eq('user_id', user.id)
          .order('submission_timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      if (lastResponse != null) {
        final lastSubmissionStr = lastResponse['submission_timestamp'] as String;
        lastSubmissionDate = DateTime.parse(lastSubmissionStr);
        
        // Calculate if 2 weeks (14 days) have passed
        final daysSinceLastSubmission = DateTime.now().difference(lastSubmissionDate!).inDays;
        final canTake = daysSinceLastSubmission >= 14;
        
        if (!canTake) {
          // Calculate next available date (14 days from last submission)
          nextAvailableDate = lastSubmissionDate!.add(const Duration(days: 14));
        }

        setState(() {
          canTakeQuestionnaire = canTake;
        });
        
        print('Last submission: $lastSubmissionDate');
        print('Days since last submission: $daysSinceLastSubmission');
        print('Can take questionnaire: $canTake');
        print('Next available date: $nextAvailableDate');
      } else {
        // No previous submissions, user can take the questionnaire
        setState(() {
          canTakeQuestionnaire = true;
        });
        print('No previous submissions found, user can take questionnaire');
      }
      
      // If user can take the questionnaire, load it
      if (canTakeQuestionnaire) {
        await _loadActiveQuestionnaire();
      } else {
        setState(() {
          isLoading = false;
        });
      }
      
    } catch (e) {
      print('Error checking bi-weekly restriction: $e');
      setState(() {
        isLoading = false;
        canTakeQuestionnaire = false;
      });
    }
  }

  Future<void> _loadActiveQuestionnaire() async {
    try {
      // First, get the active questionnaire version
      final versionData = await Supabase.instance.client
          .from('questionnaire_versions')
          .select()
          .eq('is_active', true)
          .single();

      currentVersionId = versionData['version_id'];

      // Then get all questions for this version
      final questionsData = await Supabase.instance.client
          .from('questionnaire_questions')
          .select('''
            question_id,
            question_order,
            questions (
              question_id,
              question_text,
              is_active,
              created_at,
              updated_at
            )
          ''')
          .eq('version_id', currentVersionId!)
          .order('question_order');

      final List<Question> fetchedQuestions = (questionsData as List)
          .map((data) => Question.fromMap({
                ...data['questions'],
                'options': [
                  'Not at all',
                  'Several days',
                  'More than half the days',
                  'Nearly every day',
                  'Every day'
                ],
              }))
          .toList();

      setState(() {
        questions = fetchedQuestions;
        isLoading = false;
        progress = (currentQuestionIndex + 1) / questions.length;
      });
    } catch (e) {
      print('Error loading questionnaire: $e');
      setState(() => isLoading = false);
    }
  }

  void _updateProgress() {
    setState(() {
      progress = (currentQuestionIndex + 1) / questions.length;
    });
  }

  void _nextQuestion(int selectedIndex) {
    setState(() {
      questions[currentQuestionIndex].selectedOption = selectedIndex;
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
        _updateProgress();
      } else {
        _submitAnswers();
      }
    });
  }

  Future<void> _submitAnswers() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Calculate total score
      final totalScore = questions.fold<int>(
        0,
        (sum, question) => sum + (question.selectedOption ?? 0),
      );

      // Insert questionnaire response
      final responseData = await Supabase.instance.client
          .from('questionnaire_responses')
          .insert({
            'user_id': user.id,
            'version_id': currentVersionId,
            'total_score': totalScore,
          })
          .select()
          .single();

      final responseId = responseData['response_id'];

      // Insert individual answers
      for (final question in questions) {
        if (question.selectedOption != null) {
          await Supabase.instance.client.from('questionnaire_answers').insert({
            'response_id': responseId,
            'question_id': question.questionId,
            'chosen_answer': question.selectedOption,
            'question_text_snapshot': question.questionText,
          });
        }
      }

      // Record activity completion
      await ActivityService.recordActivityCompletion('track_mood');

      if (mounted) {
        // Navigate to summary page
        Navigator.pushNamed(
          context,
          'questionnaire-summary',
          arguments: {
            'responseId': responseId,
            'totalScore': totalScore,
          },
        );
      }
    } catch (e) {
      print('Error submitting answers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error submitting answers. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const pastelBlue = Color.fromARGB(255, 242, 241, 248);
    const pastelPurple = Color(0xFFE0D4FD);

    if (isLoading) {
      return Scaffold(
        backgroundColor: pastelBlue,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show restriction screen if user cannot take questionnaire
    if (!canTakeQuestionnaire) {
      return _buildRestrictionScreen(pastelBlue);
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: pastelBlue,
        body: const Center(child: Text("No questions available.")),
      );
    }

    if (showIntroduction) {
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  const SizedBox(height: 0),

                  // Title
                  Text(
                    'Mental Health Questionnaire',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Introduction Text
                  Text(
                    'Welcome to your mental health check-in',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'This questionnaire is designed to help us understand your current mental well-being and provide appropriate support. Your honest responses will help us better assist you in your mental health journey.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF3A3A50),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Guidelines
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: pastelPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guidelines:',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBulletPoint(
                            'Take your time to answer each question thoughtfully'),
                        _buildBulletPoint(
                            'Answer as honestly as possible - there are no right or wrong answers'),
                        _buildBulletPoint(
                            'Consider how you\'ve been feeling over the past two weeks'),
                        _buildBulletPoint(
                            'Complete the questionnaire in a quiet, private space'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // History Button
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, 'questionnaire-history');
                      },
                      icon: const Icon(Icons.history, color: Color(0xFF5D5D72)),
                      label: Text(
                        'View Previous Summaries',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: const Color(0xFF5D5D72),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF5D5D72)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: pastelPurple.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Important: This questionnaire is not a substitute for professional medical advice, diagnosis, or treatment. The results should not be interpreted as a clinical diagnosis. If you\'re experiencing severe distress, please seek help from a qualified mental health professional.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF3A3A50),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Start Button
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C83FD),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          showIntroduction = false;
                        });
                      },
                      child: Text(
                        'Begin Questionnaire',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
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
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: pastelBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        title: Text(
                          'Are you sure?',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        content: Text(
                          'If you go back now, you will lose all your progress.',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF7C83FD),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, 'student-home');
                            },
                            child: Text(
                              'Yes, go back',
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF3A3A50),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),

                // Progress bar with label
                Text(
                  'Question ${currentQuestionIndex + 1} of ${questions.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white70,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color.fromARGB(255, 73, 75, 111),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Question text
                Text(
                  currentQuestion.questionText,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 20),

                // Options
                ...List.generate(
                  currentQuestion.options.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: currentQuestion.selectedOption == index
                          ? pastelPurple.withOpacity(0.8)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: currentQuestion.selectedOption == index
                            ? const Color(0xFF7C83FD)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: RadioListTile<int>(
                      title: Text(
                        currentQuestion.options[index],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      activeColor: const Color(0xFF7C83FD),
                      value: index,
                      groupValue: currentQuestion.selectedOption,
                      onChanged: (value) {
                        setState(() {
                          currentQuestion.selectedOption = value;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Next or Finish Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C83FD),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: currentQuestion.selectedOption != null
                        ? () => _nextQuestion(currentQuestion.selectedOption!)
                        : null,
                    child: Text(
                      currentQuestionIndex < questions.length - 1
                          ? 'Next'
                          : 'Finish',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF3A3A50),
              height: 1.5,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF3A3A50),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictionScreen(Color pastelBlue) {
    const pastelPurple = Color(0xFFE0D4FD);
    
    // Format dates for display
    String formatDate(DateTime date) {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }

    // Calculate days remaining
    int daysRemaining = 0;
    if (nextAvailableDate != null) {
      daysRemaining = nextAvailableDate!.difference(DateTime.now()).inDays + 1;
      if (daysRemaining < 0) daysRemaining = 0;
    }

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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                
                // Calendar Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: pastelPurple.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    size: 60,
                    color: Color(0xFF7C83FD),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Questionnaire Not Available',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 16),

                // Explanation
                Text(
                  'The Mental Health Questionnaire can only be taken once every 2 weeks to ensure meaningful assessment and prevent survey fatigue.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF5D5D72),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (lastSubmissionDate != null) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              color: Color(0xFF7C83FD),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Last completed:',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF5D5D72),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(lastSubmissionDate!),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      if (nextAvailableDate != null) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.event_available_rounded,
                              color: Color(0xFF4CAF50),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Next available:',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF5D5D72),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(nextAvailableDate!),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Days remaining
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C83FD).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            daysRemaining == 1 
                                ? '1 day remaining'
                                : '$daysRemaining days remaining',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7C83FD),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Alternative Actions
                Text(
                  'In the meantime, you can:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                _buildActionButton(
                  icon: Icons.history_rounded,
                  title: 'View Previous Summaries',
                  subtitle: 'Review your past questionnaire results',
                  onTap: () => Navigator.pushNamed(context, 'questionnaire-history'),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.spa_rounded,
                  title: 'Try Breathing Exercises',
                  subtitle: 'Practice mindfulness and relaxation',
                  onTap: () => Navigator.pushNamed(context, 'breathing-exercises'),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.book_rounded,
                  title: 'Mood Journal',
                  subtitle: 'Track your daily emotions and thoughts',
                  onTap: () => Navigator.pushNamed(context, 'journal'),
                ),
                
                const SizedBox(height: 32),
                
                // Go back button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Back to Home',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C83FD).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF7C83FD),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF5D5D72),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF5D5D72),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
