// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter/material.dart';
// import '../../components/question.dart';

// class StudentMtq extends StatefulWidget {
//   const StudentMtq({super.key});
//   @override
//   State<StudentMtq> createState() => _StudentMtqState();
// }

// class _StudentMtqState extends State<StudentMtq> {
//   List<Question> questions = [];
//   int currentQuestionIndex = 0;
//   double progress = 0;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadQuestions();
//   }

//   Future<void> _loadQuestions() async {
//     try {
//       final data =
//           await Supabase.instance.client
//               .from('questions')
//               .select(); // No type argument here

//       final List<Question> fetchedQuestions =
//           (data as List)
//               .map((questionData) => Question.fromMap(questionData))
//               .toList();

//       setState(() {
//         questions = fetchedQuestions;
//         isLoading = false;
//         progress = (currentQuestionIndex + 1) / questions.length;
//       });

//       print('Successfully fetched ${fetchedQuestions.length} questions.');
//     } catch (e) {
//       print('Error fetching questions: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   void _updateProgress() {
//     setState(() {
//       progress = (currentQuestionIndex + 1) / questions.length;
//     });
//   }

//   void _nextQuestion(int selectedIndex) {
//     setState(() {
//       questions[currentQuestionIndex].selectedOption = selectedIndex;
//       if (currentQuestionIndex < questions.length - 1) {
//         currentQuestionIndex++;
//         _updateProgress();
//       } else {
//         // All questions answered, you can show results or thank you page
//         print("Survey completed!");
//       }
//     });
//   }

//   void _submitAnswers() {
//     // You can process or send answers here
//     print("All answers submitted!");
//     // Example: navigate to a results page or show a dialog
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: Text('Thank you!'),
//             content: Text('Your responses have been submitted.'),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pushNamed(context, 'student-home');
//                 },
//                 child: Text('OK'),
//               ),
//             ],
//           ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: Text('Mood Tracking Questionnaire')),
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//     if (questions.isEmpty && !isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: Text('Mood Tracking Questionnaire')),
//         body: Center(child: Text('No questions available.')),
//       );
//     }
//     if (questions.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: Text('Mood Tracking Questionnaire')),
//         body: Center(child: Text('No questions available.')),
//       );
//     }

//     final currentQuestion = questions[currentQuestionIndex];

//     return Scaffold(
//       appBar: AppBar(title: Text('Mood Tracking Questionnaire')),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Progress bar
//               LinearProgressIndicator(
//                 value: progress,
//                 backgroundColor: Colors.grey.shade300,
//                 color: Colors.blueAccent,
//               ),
//               SizedBox(height: 20),

//               // Question text
//               Text(
//                 currentQuestion.questionText,
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
//               ),
//               SizedBox(height: 20),

//               ...List.generate(
//                 currentQuestion.options.length,
//                 (index) => RadioListTile<int>(
//                   title: Text(currentQuestion.options[index]),
//                   value: index,
//                   groupValue: currentQuestion.selectedOption,
//                   onChanged: (value) {
//                     setState(() {
//                       currentQuestion.selectedOption = value;
//                     });
//                   },
//                 ),
//               ),

//               SizedBox(height: 20),

//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   ElevatedButton(
//                     onPressed:
//                         currentQuestion.selectedOption != null
//                             ? () {
//                               if (currentQuestionIndex < questions.length - 1) {
//                                 _nextQuestion(currentQuestion.selectedOption!);
//                               } else {
//                                 _submitAnswers();
//                               }
//                             }
//                             : null,
//                     child: Text(
//                       currentQuestionIndex < questions.length - 1
//                           ? 'Next'
//                           : 'Finish',
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/question.dart';

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

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final data = await Supabase.instance.client.from('questions').select();
      final List<Question> fetchedQuestions = (data as List)
          .map((questionData) => Question.fromMap(questionData))
          .toList();

      setState(() {
        questions = fetchedQuestions;
        isLoading = false;
        progress = (currentQuestionIndex + 1) / questions.length;
      });
    } catch (e) {
      print('Error fetching questions: $e');
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

  void _submitAnswers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Thank you!"),
        content: const Text("Your responses have been submitted."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, 'student-home'),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pastelBlue = const Color.fromARGB(255, 242, 241, 248);
    final pastelPurple = const Color(0xFFE0D4FD);

    if (isLoading) {
      return Scaffold(
        backgroundColor: pastelBlue,
        body: const Center(child: CircularProgressIndicator()),
      );
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
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, 'student-home'),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF3A3A50),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 32),

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
                  Text(
                    'Guidelines:',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFF7C83FD), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          onPressed: () =>
                              Navigator.pop(context), // Close dialog
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF7C83FD),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color.fromARGB(255, 73, 75, 111),
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

              const Spacer(),

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
            ],
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
                color: Color(0xFF3A3A50),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
