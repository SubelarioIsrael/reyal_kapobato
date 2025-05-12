import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final response =
        await Supabase.instance.client
            .from('questions') // Assuming 'questions' is your table name
            .select();

    if (response is List) {
      final List<Question> fetchedQuestions =
          response
              .map((questionData) => Question.fromMap(questionData))
              .toList();

      setState(() {
        questions = fetchedQuestions;
        isLoading = false;
        progress = (currentQuestionIndex + 1) / questions.length;
      });
    } else {
      // Handle error
      print('Error fetching questions: Unable to fetch data from Supabase.');
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
        // All questions answered, you can show results or thank you page
        print("Survey completed!");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Personality Test')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(title: Text('Personality Test')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade300,
                color: Colors.blueAccent,
              ),
              SizedBox(height: 20),

              // Question text
              Text(
                currentQuestion.questionText,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 20),

              // Likert scale options (radio buttons)
              ...List.generate(
                currentQuestion.options.length,
                (index) => RadioListTile<int>(
                  title: Text(currentQuestion.options[index]),
                  value: index,
                  groupValue: currentQuestion.selectedOption,
                  onChanged: (value) {
                    _nextQuestion(value!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
