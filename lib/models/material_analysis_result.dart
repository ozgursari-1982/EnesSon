/// Model for structured material analysis results
/// This replaces free-text analysis with parseable JSON structure
class MaterialAnalysisResult {
  final List<String> mainTopics;
  final List<String> keyConcepts;
  final List<String> importantPoints;
  final String contentType; // ödev_kağıdı, ders_notu, sınav_kağıdı, çalışma_föyü, kitap_sayfası
  final String contentDetail;
  final List<String> studyRecommendations;
  final ExamPreparationInfo examPreparation;

  MaterialAnalysisResult({
    required this.mainTopics,
    required this.keyConcepts,
    required this.importantPoints,
    required this.contentType,
    required this.contentDetail,
    required this.studyRecommendations,
    required this.examPreparation,
  });

  factory MaterialAnalysisResult.fromJson(Map<String, dynamic> json) {
    return MaterialAnalysisResult(
      mainTopics: List<String>.from(json['mainTopics'] ?? []),
      keyConcepts: List<String>.from(json['keyConcepts'] ?? []),
      importantPoints: List<String>.from(json['importantPoints'] ?? []),
      contentType: json['contentType'] ?? 'ders_notu',
      contentDetail: json['contentDetail'] ?? '',
      studyRecommendations: List<String>.from(json['studyRecommendations'] ?? []),
      examPreparation: ExamPreparationInfo.fromJson(json['examPreparation'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mainTopics': mainTopics,
      'keyConcepts': keyConcepts,
      'importantPoints': importantPoints,
      'contentType': contentType,
      'contentDetail': contentDetail,
      'studyRecommendations': studyRecommendations,
      'examPreparation': examPreparation.toJson(),
    };
  }

  /// Convert to human-readable text for display
  String toReadableText() {
    return '''
📚 ANA KONULAR:
${mainTopics.map((t) => '• $t').join('\n')}

💡 ÖNEMLİ KAVRAMLAR:
${keyConcepts.map((k) => '• $k').join('\n')}

⚠️ DİKKAT EDİLMESİ GEREKENLER:
${importantPoints.map((p) => '• $p').join('\n')}

📊 İÇERİK DETAYI:
$contentDetail

📝 ÇALIŞMA ÖNERİLERİ:
${studyRecommendations.map((r) => '• $r').join('\n')}

✅ SINAV HAZIRLIĞI:
${examPreparation.toReadableText()}
''';
  }
}

/// Information about exam preparation from material
class ExamPreparationInfo {
  final List<String> questionTypes;
  final String difficulty;
  final int estimatedQuestions;

  ExamPreparationInfo({
    required this.questionTypes,
    required this.difficulty,
    required this.estimatedQuestions,
  });

  factory ExamPreparationInfo.fromJson(Map<String, dynamic> json) {
    return ExamPreparationInfo(
      questionTypes: List<String>.from(json['questionTypes'] ?? []),
      difficulty: json['difficulty'] ?? 'orta',
      estimatedQuestions: json['estimatedQuestions'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionTypes': questionTypes,
      'difficulty': difficulty,
      'estimatedQuestions': estimatedQuestions,
    };
  }

  String toReadableText() {
    return '''
Soru Tipleri: ${questionTypes.join(', ')}
Zorluk: $difficulty
Tahmini Soru Sayısı: $estimatedQuestions
''';
  }
}
