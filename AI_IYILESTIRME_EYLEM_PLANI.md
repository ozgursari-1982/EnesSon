# 🎯 AI Öğretmen - İyileştirme Eylem Planı

**Hedef:** AI öğretmen işlevselliğini mükemmelleştirme  
**Toplam Süre:** ~37 saat (5 iş günü)  
**Kapsam:** Sadece AI özellikleri (güvenlik, API, iOS sonra)

---

## 📅 FAZ 1: ACİL DÜZELTMELER (1. Gün - 8 saat)

### 🔴 Görev 1.1: Soru Kalitesi Validasyonu (2 saat)

**Dosya:** `lib/services/gemini_ai_service.dart`

**Yapılacaklar:**

```dart
// 1. Validasyon fonksiyonu ekle (lib/services/gemini_ai_service.dart)
bool _validateQuestion(Map<String, dynamic> q) {
  // Temel alan kontrolleri
  if (q['question']?.toString().isEmpty ?? true) return false;
  if (q['explanation']?.toString().isEmpty ?? true) return false;
  
  // Şık sayısı kontrolü
  final options = q['options'] as List?;
  if (options == null || options.length != 4) return false;
  
  // Doğru cevap indeksi kontrolü
  final correctIndex = q['correctAnswerIndex'];
  if (correctIndex == null || correctIndex < 0 || correctIndex >= 4) return false;
  
  // Şık benzersizliği
  if (options.toSet().length != 4) return false;
  
  // Minimum uzunluk
  if (q['question'].toString().length < 10) return false;
  
  return true;
}

// 2. generateTest() metodunu güncelle
Future<List<Question>> generateTest(...) async {
  // ... mevcut kod ...
  
  final validQuestions = <Question>[];
  final invalidQuestions = <String>[];
  
  for (var q in data['questions']) {
    if (_validateQuestion(q)) {
      validQuestions.add(Question(
        id: _uuid.v4(),
        question: q['question'],
        options: List<String>.from(q['options']),
        correctAnswerIndex: q['correctAnswerIndex'],
        explanation: q['explanation'],
      ));
    } else {
      invalidQuestions.add(q['question']?.toString() ?? 'Bilinmeyen soru');
      print('⚠️ Geçersiz soru: ${q['question']}');
    }
  }
  
  // Yeterli geçerli soru var mı?
  if (validQuestions.length < questionCount * 0.8) {
    throw '''
Yeterli kaliteli soru üretilemedi.
Geçerli: ${validQuestions.length}
Geçersiz: ${invalidQuestions.length}
Lütfen tekrar deneyin veya farklı materyaller ekleyin.
''';
  }
  
  return validQuestions;
}
```

**Test:**
- [ ] Geçersiz JSON ile test et
- [ ] 3 şıklı soru ile test et
- [ ] Boş açıklama ile test et
- [ ] Hatalı indeks ile test et

---

### 🔴 Görev 1.2: JSON Yapılandırılmış Analiz (3 saat)

**Dosya:** `lib/services/gemini_ai_service.dart`

**Yapılacaklar:**

```dart
// 1. MaterialAnalysisResult modeli oluştur (lib/models/material_analysis_result.dart)
class MaterialAnalysisResult {
  List<String> mainTopics;
  List<String> keyConcepts;
  List<String> importantPoints;
  String contentType; // ödev_kağıdı, ders_notu, sınav_kağıdı
  String contentDetail;
  List<String> studyRecommendations;
  ExamPreparationInfo examPreparation;
  
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
}

class ExamPreparationInfo {
  List<String> questionTypes;
  String difficulty;
  int estimatedQuestions;
  
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
}

// 2. analyzeStudyMaterialWithFile() metodunu güncelle
Future<MaterialAnalysisResult> analyzeStudyMaterialWithFile(...) async {
  // Prompt'u JSON döndürecek şekilde güncelle
  final prompt = '''
  ...
  
  Çıktı formatı (SADECE JSON, başka metin yok):
  {
    "mainTopics": ["Konu 1", "Konu 2"],
    "keyConcepts": ["Kavram 1", "Kavram 2"],
    "importantPoints": ["Nokta 1", "Nokta 2"],
    "contentType": "ödev_kağıdı",
    "contentDetail": "İçerik açıklaması",
    "studyRecommendations": ["Öneri 1", "Öneri 2"],
    "examPreparation": {
      "questionTypes": ["Hesaplama", "Problem"],
      "difficulty": "orta",
      "estimatedQuestions": 5
    }
  }
  ''';
  
  final response = await _model.generateContent([...]);
  final text = response.text;
  
  // JSON parse et
  final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text ?? '');
  if (jsonMatch == null) throw 'JSON bulunamadı';
  
  final jsonData = json.decode(jsonMatch.group(0)!);
  return MaterialAnalysisResult.fromJson(jsonData);
}
```

**Test:**
- [ ] PDF analizi JSON döndürüyor mu?
- [ ] Resim analizi JSON döndürüyor mu?
- [ ] Parse hataları yakalanıyor mu?

---

### 🔴 Görev 1.3: Materyal Referans Takibi (3 saat)

**Dosyalar:** `lib/models/test.dart`, `lib/services/gemini_ai_service.dart`

**Yapılacaklar:**

```dart
// 1. Question modeline yeni alanlar ekle (lib/models/test.dart)
class Question {
  String id;
  String question;
  List<String> options;
  int correctAnswerIndex;
  String explanation;
  
  // YENİ ALANLAR
  String? sourceMaterialId;
  String? sourceMaterialTitle;
  String? topic; // Hangi konu?
  
  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    this.sourceMaterialId,
    this.sourceMaterialTitle,
    this.topic,
  });
  
  // toMap ve fromMap metodlarını güncelle
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'sourceMaterialId': sourceMaterialId, // YENİ
      'sourceMaterialTitle': sourceMaterialTitle, // YENİ
      'topic': topic, // YENİ
    };
  }
  
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      explanation: map['explanation'] ?? '',
      sourceMaterialId: map['sourceMaterialId'], // YENİ
      sourceMaterialTitle: map['sourceMaterialTitle'], // YENİ
      topic: map['topic'], // YENİ
    );
  }
}

// 2. generateTest() metodunu güncelle
Future<List<Question>> generateTest({
  required String courseName,
  required List<MaterialWithId> materialAnalyses, // ID'li liste
  required int questionCount,
  String difficulty = 'orta',
}) async {
  
  // Materyalleri numara ile eşle
  final materialMap = <String, MaterialWithId>{};
  for (int i = 0; i < materialAnalyses.length; i++) {
    materialMap['MAT_$i'] = materialAnalyses[i];
  }
  
  final prompt = '''
  MATERYALLER:
  ${materialAnalyses.asMap().entries.map((e) {
    return '''
    [MAT_${e.key}] "${e.value.title}"
    ${e.value.analysis}
    ''';
  }).join('\n---\n')}
  
  Her soru için "sourceMaterialId" döndür:
  {
    "questions": [
      {
        "question": "...",
        "options": [...],
        "correctAnswerIndex": 0,
        "explanation": "...",
        "sourceMaterialId": "MAT_0",  // YENİ!
        "topic": "Toplama İşlemi"      // YENİ!
      }
    ]
  }
  ''';
  
  // ... parse ...
  
  for (var q in data['questions']) {
    final materialId = q['sourceMaterialId'];
    final material = materialMap[materialId];
    
    questions.add(Question(
      id: _uuid.v4(),
      question: q['question'],
      options: List<String>.from(q['options']),
      correctAnswerIndex: q['correctAnswerIndex'],
      explanation: q['explanation'],
      sourceMaterialId: material?.id,        // YENİ!
      sourceMaterialTitle: material?.title,  // YENİ!
      topic: q['topic'],                     // YENİ!
    ));
  }
}

class MaterialWithId {
  String id;
  String title;
  String analysis;
  
  MaterialWithId({
    required this.id,
    required this.title,
    required this.analysis,
  });
}
```

**Test:**
- [ ] Sorular materyal ID'si ile kaydediliyor mu?
- [ ] Test sonuç ekranında materyal adı gösteriliyor mu?
- [ ] Yanlış sorudan ilgili materyale gidilebiliyor mu?

---

## ⚡ FAZ 2: KRİTİK ÖZELLİKLER (2-3. Gün - 16 saat)

### 🟡 Görev 2.1: Öğretmen Profili Otomasyonu (12 saat)

**EN KRİTİK İYİLEŞTİRME!**

**Dosyalar:** 
- `lib/services/automatic_teacher_profile_service.dart` (YENİ)
- `lib/screens/course_detail_screen.dart`
- `lib/services/firestore_service.dart`

**Yapılacaklar:**

```dart
// 1. Otomatik sistem servisi oluştur
// lib/services/automatic_teacher_profile_service.dart
class AutomaticTeacherProfileService {
  final TeacherStyleAnalyzer _analyzer = TeacherStyleAnalyzer();
  final FirestoreService _firestore = FirestoreService();
  
  // Materyal yüklendiğinde otomatik çağrılır
  Future<void> onMaterialUploaded({
    required String materialId,
    required String courseId,
    required String studentId,
    required String filePath,
    required String courseName,
    required String teacherName,
    required String documentTitle,
  }) async {
    try {
      print('📄 Öğretmen stili analiz ediliyor...');
      
      // 1. Belgeyi analiz et
      final analysis = await _analyzer.analyzeDocumentForTeacherStyle(
        filePath: filePath,
        courseName: courseName,
        documentTitle: documentTitle,
        teacherName: teacherName,
        documentId: materialId,
      );
      
      // 2. Firestore'a kaydet
      await _firestore.collection('document_analyses')
          .doc(materialId)
          .set(analysis.toMap());
      
      print('✅ Belge analizi kaydedildi');
      
      // 3. Profil güncelleme kontrolü
      await _checkAndUpdateProfile(
        courseId: courseId,
        studentId: studentId,
        courseName: courseName,
        teacherName: teacherName,
      );
      
    } catch (e) {
      print('❌ Otomatik analiz hatası: $e');
    }
  }
  
  // Profil güncelleme kontrolü
  Future<void> _checkAndUpdateProfile({
    required String courseId,
    required String studentId,
    required String courseName,
    required String teacherName,
  }) async {
    // Kaç belge analiz edildi?
    final analysisSnapshot = await _firestore
        .collection('document_analyses')
        .where('courseId', isEqualTo: courseId)
        .get();
    
    final analysisCount = analysisSnapshot.docs.length;
    
    print('📊 Analiz edilen belge sayısı: $analysisCount');
    
    if (analysisCount >= 3) {
      print('🎓 Yeterli belge var! Profil oluşturuluyor...');
      
      // Profil oluştur
      final profile = await _analyzer.buildTeacherProfile(
        courseId: courseId,
        studentId: studentId,
        courseName: courseName,
        teacherName: teacherName,
      );
      
      if (profile != null) {
        // Kaydet
        await _firestore.collection('teacher_profiles')
            .doc(courseId)
            .set(profile.toMap());
        
        print('✅ Öğretmen profili kaydedildi!');
        
        // Bildirim gönder (opsiyonel)
        // TODO: Push notification ekle
      }
    } else {
      print('⏳ ${3 - analysisCount} belge daha gerekli');
    }
  }
  
  // Profil durumunu al
  Future<ProfileStatus> getProfileStatus(String courseId) async {
    final profileDoc = await _firestore
        .collection('teacher_profiles')
        .doc(courseId)
        .get();
    
    if (profileDoc.exists) {
      final profile = TeacherStyleProfile.fromMap(profileDoc.data()!);
      return ProfileStatus(
        isReady: true,
        profile: profile,
        analysisCount: profile.totalDocumentsAnalyzed,
        message: '🎓 Öğretmen profili hazır!',
      );
    }
    
    // Kaç belge analiz edilmiş?
    final analysisSnapshot = await _firestore
        .collection('document_analyses')
        .where('courseId', isEqualTo: courseId)
        .get();
    
    final count = analysisSnapshot.docs.length;
    
    return ProfileStatus(
      isReady: false,
      analysisCount: count,
      remainingCount: 3 - count,
      message: '⏳ ${3 - count} belge daha yükle!',
    );
  }
}

class ProfileStatus {
  bool isReady;
  TeacherStyleProfile? profile;
  int analysisCount;
  int remainingCount;
  String message;
  
  ProfileStatus({
    required this.isReady,
    this.profile,
    this.analysisCount = 0,
    this.remainingCount = 3,
    required this.message,
  });
}

// 2. UI Widget oluştur
// lib/widgets/teacher_profile_widget.dart
class TeacherProfileWidget extends StatelessWidget {
  final String courseId;
  final AutomaticTeacherProfileService _service = AutomaticTeacherProfileService();
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileStatus>(
      future: _service.getProfileStatus(courseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        
        final status = snapshot.data!;
        
        if (status.isReady) {
          // Profil hazır!
          return _buildReadyProfile(context, status.profile!);
        } else {
          // Henüz profil yok
          return _buildProgressCard(context, status);
        }
      },
    );
  }
  
  Widget _buildReadyProfile(BuildContext context, TeacherStyleProfile profile) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎓 ${profile.teacherName}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Öğretmen Profili Hazır!',
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            Text('📊 ${profile.totalQuestionsFound} soru analiz edildi'),
            Text('📚 ${profile.totalDocumentsAnalyzed} belge incelendi'),
            Text('🎯 Sınav Tahmini: %${(profile.examPrediction.overallConfidence * 100).toInt()}'),
            
            SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: () => _generateRealisticExam(context, profile),
              icon: Icon(Icons.quiz),
              label: Text('Gerçekçi Sınav Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressCard(BuildContext context, ProfileStatus status) {
    final progress = status.analysisCount / 3;
    
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔍 Öğretmen Stili Öğreniliyor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(status.message),
            SizedBox(height: 16),
            
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 8),
            
            Text('${status.analysisCount}/3 belge analiz edildi'),
            
            if (status.remainingCount > 0) ...[
              SizedBox(height: 16),
              Text(
                '💡 İpucu: ${status.remainingCount} belge daha yükleyince öğretmenin soru sorma stilini öğreneceğim!',
                style: TextStyle(color: Colors.blue[700], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _generateRealisticExam(BuildContext context, TeacherStyleProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GenerateRealisticExamScreen(
          profile: profile,
        ),
      ),
    );
  }
}

// 3. Upload material screen'e entegre et
// lib/screens/upload_material_screen.dart içinde:

// Materyal yüklendikten sonra:
final service = AutomaticTeacherProfileService();
await service.onMaterialUploaded(
  materialId: material.id,
  courseId: widget.courseId,
  studentId: widget.studentId,
  filePath: filePath,
  courseName: widget.courseName,
  teacherName: widget.teacherName,
  documentTitle: titleController.text,
);
```

**Test:**
- [ ] Materyal yüklenince otomatik analiz yapılıyor mu?
- [ ] 3 belge yüklenince profil oluşturuluyor mu?
- [ ] Profil widget'ı doğru görünüyor mu?
- [ ] Gerçekçi sınav oluşturma çalışıyor mu?

---

### 🟡 Görev 2.2: Soru Çeşitliliği Garantisi (4 saat)

**Yapılacaklar:**

```dart
// lib/services/gemini_ai_service.dart

Future<List<Question>> generateTest({
  required String courseName,
  required List<MaterialWithId> materialAnalyses,
  required int questionCount,
  String difficulty = 'orta',
  Map<String, int>? topicDistribution, // YENİ PARAMETRE!
}) async {
  
  // Eğer dağılım belirtilmemişse, materyallerden otomatik çıkar
  if (topicDistribution == null) {
    topicDistribution = _extractTopicDistribution(
      materialAnalyses,
      questionCount,
    );
  }
  
  final prompt = '''
  ...
  
  KONU DAĞILIMI (MUTLAKA UYULMALI!):
  ${topicDistribution.entries.map((e) => '- ${e.key}: ${e.value} soru').join('\n')}
  
  ÖNEMLİ: Bu dağılıma tam olarak uy! Her konudan belirtilen sayıda soru oluştur!
  ''';
  
  // ... mevcut kod ...
  
  // Dağılım kontrolü
  final topicCounts = <String, int>{};
  for (var q in questions) {
    topicCounts[q.topic ?? 'Diğer'] = (topicCounts[q.topic ?? 'Diğer'] ?? 0) + 1;
  }
  
  print('🎯 Hedef dağılım: $topicDistribution');
  print('📊 Gerçek dağılım: $topicCounts');
}

Map<String, int> _extractTopicDistribution(
  List<MaterialWithId> materials,
  int questionCount,
) {
  // Materyallerdeki konuları çıkar ve dengeli dağıt
  final allTopics = <String>[];
  
  for (var material in materials) {
    // MaterialAnalysisResult'tan konuları çıkar
    final result = MaterialAnalysisResult.fromJson(
      json.decode(material.analysis)
    );
    allTopics.addAll(result.mainTopics);
  }
  
  // Tekrar edenleri say
  final topicFrequency = <String, int>{};
  for (var topic in allTopics) {
    topicFrequency[topic] = (topicFrequency[topic] ?? 0) + 1;
  }
  
  // En sık görülen konuları seç ve dağıt
  final sortedTopics = topicFrequency.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  final distribution = <String, int>{};
  final topTopics = sortedTopics.take(3).toList();
  
  // Toplam soru sayısını dağıt
  int remaining = questionCount;
  for (int i = 0; i < topTopics.length; i++) {
    final topic = topTopics[i].key;
    final share = (remaining / (topTopics.length - i)).round();
    distribution[topic] = share;
    remaining -= share;
  }
  
  return distribution;
}
```

**Test:**
- [ ] Soru dağılımı hedefle uyuşuyor mu?
- [ ] Tüm konulardan soru geliyor mu?
- [ ] Otomatik dağılım dengeli mi?

---

## 💎 FAZ 3: GELİŞMİŞ ÖZELLİKLER (4-5. Gün - 13 saat)

### 🟢 Görev 3.1: Adaptif Öğrenme Sistemi (8 saat)

[Detaylı implementasyon burada...]

### 🟢 Görev 3.2: Öğrenci Seviyesi Adaptasyonu (2 saat)

[Detaylı implementasyon burada...]

### 🟢 Görev 3.3: Profil Doldurmayı Teşvik (3 saat)

[Detaylı implementasyon burada...]

---

## ✅ TEST VE DOĞRULAMA

Her faz sonunda:
- [ ] Unit testler çalıştır
- [ ] Manuel test yap
- [ ] Kullanıcı deneyimi kontrol et
- [ ] Performance ölç
- [ ] Hata loglarını incele

---

## 📊 BAŞARI METRİKLERİ

### Faz 1 Sonrası
- [ ] Hatalı test oranı %80 azaldı
- [ ] JSON parse başarı oranı %100
- [ ] Materyal referansı %100 çalışıyor

### Faz 2 Sonrası
- [ ] Öğretmen profili kullanım oranı %0 → %60
- [ ] Soru çeşitliliği skoru 7+/10

### Faz 3 Sonrası
- [ ] Adaptif test başarı oranı %70+
- [ ] Profil tamamlama oranı %40+

---

**Hazırlayan:** AI Analiz Sistemi  
**Tarih:** 10 Kasım 2025
