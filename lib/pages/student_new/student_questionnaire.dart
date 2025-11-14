import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../controllers/student_questionnaire_controller.dart';

class StudentQuestionnaire extends StatefulWidget {
  const StudentQuestionnaire({super.key});
  
  @override
  State<StudentQuestionnaire> createState() => _StudentQuestionnaireState();
}

class _StudentQuestionnaireState extends State<StudentQuestionnaire> {
  final controller = StudentQuestionnaireController();
  bool showIntroduction = true;
  bool showSafetyWarning = false;

  @override
  void initState() {
    super.initState();
    controller.init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
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
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Error',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A50),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFF3A3A50),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF7C83FD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextQuestion(int selectedIndex) {
    bool isSelfHarmQuestion = controller.currentQuestionIndex.value == 8 && selectedIndex >= 1;

    if (isSelfHarmQuestion && !showSafetyWarning) {
      setState(() {
        controller.questions.value[controller.currentQuestionIndex.value].selectedOption = selectedIndex;
        showSafetyWarning = true;
      });
      return;
    }

    controller.selectAnswer(selectedIndex);

    if (controller.currentQuestionIndex.value < controller.questions.value.length - 1) {
      controller.nextQuestion();
    } else {
      _submitAnswers();
    }
  }

  Future<void> _submitAnswers() async {
    final result = await controller.submitAnswers();
    
    if (!mounted) return;

    if (result['success']) {
      Navigator.pushNamed(
        context,
        'questionnaire-summary',
        arguments: {
          'responseId': result['responseId'],
          'totalScore': result['totalScore'],
        },
      );
    } else {
      _showErrorDialog(result['error'] ?? 'Error submitting answers. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const pastelBlue = Color.fromARGB(255, 242, 241, 248);
    const pastelPurple = Color(0xFFE0D4FD);

    return ValueListenableBuilder(
      valueListenable: controller.isLoading,
      builder: (_, bool isLoading, __) {
        if (isLoading) {
          return Scaffold(
            backgroundColor: pastelBlue,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return ValueListenableBuilder(
          valueListenable: controller.canTakeQuestionnaire,
          builder: (_, bool canTake, __) {
            if (!canTake) {
              return _buildRestrictionScreen(pastelBlue);
            }

            if (controller.questions.value.isEmpty) {
              return Scaffold(
                backgroundColor: pastelBlue,
                body: const Center(child: Text("No questions available.")),
              );
            }

            if (showIntroduction) {
              return _buildIntroductionScreen(pastelBlue, pastelPurple);
            }

            if (showSafetyWarning) {
              return _buildSafetyWarningScreen(pastelBlue);
            }

            return _buildQuestionScreen(pastelBlue, pastelPurple);
          },
        );
      },
    );
  }

  Widget _buildIntroductionScreen(Color pastelBlue, Color pastelPurple) {
    return Scaffold(
      backgroundColor: pastelBlue,
      appBar: AppBar(
        backgroundColor: pastelBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5D5D72)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Questionnaire",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
        actions: const [StudentNotificationButton()],
      ),
      drawer: const StudentDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mental Health Questionnaire',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 24),
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
                'This questionnaire consists of two standardized screening tools to help assess your current well-being. Please consider how you have been feeling over the past two weeks when answering all questions.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF3A3A50),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: pastelPurple.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This questionnaire includes:',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBulletPoint('PHQ-9: Depression screening (9 questions)'),
                    _buildBulletPoint('GAD-7: Anxiety screening (7 questions)'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                    _buildBulletPoint('Answer honestly - there are no right or wrong answers'),
                    _buildBulletPoint('Consider your experiences over the past two weeks'),
                    _buildBulletPoint('Complete in a quiet, private space'),
                    _buildBulletPoint('Take your time with each question'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Important Safety Notice',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This questionnaire includes questions about thoughts of self-harm. If you are having thoughts of hurting yourself or others, please seek immediate help from:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.orange.shade800,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Campus Counseling Services\n• National Suicide Prevention Lifeline: 988\n• Emergency Services: 911',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.orange.shade800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, 'questionnaire-history');
                  },
                  icon: const Icon(Icons.history, color: Color(0xFF5D5D72)),
                  label: Text(
                    'View Previous Results',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF5D5D72),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF5D5D72)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: pastelPurple.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Important: This screening tool is not a diagnostic instrument and should not replace professional mental health assessment. Results are for educational and self-awareness purposes only. If you have concerns about your mental health, please consult with a qualified healthcare professional.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF3A3A50),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() {
                      showIntroduction = false;
                    });
                  },
                  child: Text(
                    'Begin Assessment',
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
    );
  }

  Widget _buildSafetyWarningScreen(Color pastelBlue) {
    return Scaffold(
      backgroundColor: pastelBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'We Care About You',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your response indicates you may be having thoughts of self-harm. Please know that help is available and things can get better.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF3A3A50),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Immediate Help Available:',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crisis Text Line: Text HOME to 741741\nNational Suicide Prevention Lifeline: 988\nEmergency Services: 911',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.red.shade700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(context, 'student-counselors'),
                            child: Text(
                              'Find Counselor',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF7C83FD),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C83FD),
                            ),
                            onPressed: () {
                              setState(() {
                                showSafetyWarning = false;
                                if (controller.currentQuestionIndex.value < controller.questions.value.length - 1) {
                                  controller.nextQuestion();
                                } else {
                                  _submitAnswers();
                                }
                              });
                            },
                            child: Text(
                              'Continue',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionScreen(Color pastelBlue, Color pastelPurple) {
    return ValueListenableBuilder(
      valueListenable: controller.currentQuestionIndex,
      builder: (_, int index, __) {
        final currentQuestion = controller.questions.value[index];
        
        return Scaffold(
          backgroundColor: pastelBlue,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            contentPadding: const EdgeInsets.all(24),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Are you sure?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF3A3A50),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            content: Text(
                              'If you go back now, you will lose all your progress.',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: const Color(0xFF3A3A50),
                              ),
                            ),
                            actions: [
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        side: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF7C83FD),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pushNamed(context, 'student-home');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 2,
                                      ),
                                      child: Text(
                                        'Yes, go back',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
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
                      },
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF3A3A50),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ValueListenableBuilder(
                      valueListenable: controller.currentSection,
                      builder: (_, String section, __) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C83FD).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            section,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7C83FD),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Question ${index + 1} of ${controller.questions.value.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder(
                      valueListenable: controller.progress,
                      builder: (_, double progress, __) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.white70,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(255, 73, 75, 111),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    Text(
                      currentQuestion.questionText,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(
                      currentQuestion.options.length,
                      (optionIndex) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: currentQuestion.selectedOption == optionIndex
                              ? pastelPurple.withOpacity(0.8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: currentQuestion.selectedOption == optionIndex
                                ? const Color(0xFF7C83FD)
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: RadioListTile<int>(
                          title: Text(
                            currentQuestion.options[optionIndex],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                          activeColor: const Color(0xFF7C83FD),
                          value: optionIndex,
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: ValueListenableBuilder(
                        valueListenable: controller.isSubmitting,
                        builder: (_, bool isSubmitting, __) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C83FD),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: (currentQuestion.selectedOption != null && !isSubmitting)
                                ? () => _nextQuestion(currentQuestion.selectedOption!)
                                : null,
                            child: isSubmitting && index == controller.questions.value.length - 1
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    index < controller.questions.value.length - 1 ? 'Next' : 'Finish',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 16, color: Color(0xFF3A3A50), height: 1.5)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF3A3A50), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictionScreen(Color pastelBlue) {
    const pastelPurple = Color(0xFFE0D4FD);

    String formatDate(DateTime date) {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }

    return ValueListenableBuilder(
      valueListenable: controller.nextAvailableDate,
      builder: (_, DateTime? nextDate, __) {
        int daysRemaining = 0;
        if (nextDate != null) {
          daysRemaining = nextDate.difference(DateTime.now()).inDays + 1;
          if (daysRemaining < 0) daysRemaining = 0;
        }

        return Scaffold(
          backgroundColor: pastelBlue,
          appBar: AppBar(
            backgroundColor: pastelBlue,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5D5D72)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              "Questionnaire",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3A3A50),
              ),
            ),
            centerTitle: true,
            actions: const [StudentNotificationButton()],
          ),
          drawer: const StudentDrawer(),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: pastelPurple.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.schedule_rounded, size: 60, color: Color(0xFF7C83FD)),
                  ),
                  const SizedBox(height: 24),
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
                  ValueListenableBuilder(
                    valueListenable: controller.lastSubmissionDate,
                    builder: (_, DateTime? lastDate, __) {
                      return Container(
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
                            if (lastDate != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.history_rounded, color: Color(0xFF7C83FD), size: 20),
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
                                formatDate(lastDate),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (nextDate != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.event_available_rounded, color: Color(0xFF4CAF50), size: 20),
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
                                formatDate(nextDate),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C83FD).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  daysRemaining == 1 ? '1 day remaining' : '$daysRemaining days remaining',
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
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'In the meantime, you can:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    onTap: () => Navigator.pushNamed(context, 'student-breathing-exercises'),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    icon: Icons.book_rounded,
                    title: 'Mood Journal',
                    subtitle: 'Track your daily emotions and thoughts',
                    onTap: () => Navigator.pushNamed(context, 'student-journal-entries'),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C83FD),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        );
      },
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
              child: Icon(icon, color: const Color(0xFF7C83FD), size: 24),
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
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF5D5D72)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF5D5D72), size: 16),
          ],
        ),
      ),
    );
  }
}
