class Test {
  final String id;
  final String courseId;
  final String studentId;
  final String title;
  final List<Question> questions;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, String>? studentAnswers; // questionId -> answer
  final double? score;

  Test({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.title,
    required this.questions,
    required this.createdAt,
    this.completedAt,
    this.studentAnswers,
    this.score,
  });

  bool get isCompleted => completedAt != null;

  factory Test.fromMap(Map<String, dynamic> map, String id) {
    // Helper function to parse date from various formats
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        return DateTime.parse(value);
      }
      // Firestore Timestamp
      if (value is Map && value.containsKey('_seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
      }
      // Try to get toDate method (Firestore Timestamp object)
      try {
        return (value as dynamic).toDate();
      } catch (e) {
        return null;
      }
    }

    return Test(
      id: id,
      courseId: map['courseId'] ?? '',
      studentId: map['studentId'] ?? '',
      title: map['title'] ?? '',
      questions: (map['questions'] as List<dynamic>?)
              ?.map((q) => Question.fromMap(q))
              .toList() ??
          [],
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      completedAt: parseDate(map['completedAt']),
      studentAnswers: map['studentAnswers'] != null
          ? Map<String, String>.from(map['studentAnswers'])
          : null,
      score: map['score']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'studentId': studentId,
      'title': title,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'studentAnswers': studentAnswers,
      'score': score,
    };
  }
}

class Question {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;
  
  // PHASE 1.3: Material reference tracking
  final String? sourceMaterialId;    // ID of the material this question came from
  final String? sourceMaterialTitle; // Title of the material for easy reference
  final String? topic;               // Specific topic this question covers

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
    this.sourceMaterialId,
    this.sourceMaterialTitle,
    this.topic,
  });

  // Getter to provide the correct answer value
  String get correctAnswerValue {
    if (correctAnswerIndex >= 0 && correctAnswerIndex < options.length) {
      return options[correctAnswerIndex];
    }
    return 'N/A'; // Not Available
  }

  // Getter to provide the correct answer key (A, B, C...)
  String get correctAnswerKey {
    if (correctAnswerIndex >= 0 && correctAnswerIndex < options.length) {
      return String.fromCharCode('A'.codeUnitAt(0) + correctAnswerIndex);
    }
    return 'N/A';
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      explanation: map['explanation'],
      sourceMaterialId: map['sourceMaterialId'],
      sourceMaterialTitle: map['sourceMaterialTitle'],
      topic: map['topic'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'sourceMaterialId': sourceMaterialId,
      'sourceMaterialTitle': sourceMaterialTitle,
      'topic': topic,
    };
  }
}

