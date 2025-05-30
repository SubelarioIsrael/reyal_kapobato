class Question {
  final int questionId;
  final String questionText;
  final List<String> options;
  int? selectedOption;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Question({
    required this.questionId,
    required this.questionText,
    required this.options,
    this.selectedOption,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      questionId: map['question_id'] as int,
      questionText: map['question_text'] as String,
      options: List<String>.from(map['options'] as List),
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question_id': questionId,
      'question_text': questionText,
      'options': options,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
