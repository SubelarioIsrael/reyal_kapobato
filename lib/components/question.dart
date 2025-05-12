class Question {
  final String questionText;
  final List<String> options;
  int selectedOption = -1; // To keep track of the user's selection

  Question({required this.questionText, required this.options});

  // Factory constructor to create a Question object from a Supabase row
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      questionText: map['question_text'],
      options: [
        map['option_1'],
        map['option_2'],
        map['option_3'],
        map['option_4'],
        map['option_5'],
      ],
    );
  }
}
