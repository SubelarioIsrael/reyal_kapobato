class Question {
  final String questionText;
  final List<String> options;
  int? selectedOption;

  Question({
    required this.questionText,
    required this.options,
    this.selectedOption,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      questionText: map['question_text'] as String,
      options: List<String>.from(map['options'] as List),
    );
  }
}
