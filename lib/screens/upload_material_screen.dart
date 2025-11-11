import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/course.dart';
import '../models/study_material.dart';
import '../services/firebase_storage_service.dart';
import '../services/firestore_service.dart';
import '../services/gemini_ai_service.dart';
import '../services/teacher_style_analyzer.dart';
import '../services/automatic_teacher_profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadMaterialScreen extends StatefulWidget {
  final Course course;

  const UploadMaterialScreen({super.key, required this.course});

  @override
  State<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends State<UploadMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _storageService = FirebaseStorageService();
  final _firestoreService = FirestoreService();
  final _aiService = GeminiAIService();
  final _teacherAnalyzer = TeacherStyleAnalyzer();
  final _imagePicker = ImagePicker();
  final _automaticProfileService = AutomaticTeacherProfileService(); // PHASE 2.2: Add automatic profile service

  dynamic _selectedFile; // File for mobile, PlatformFile for web
  String? _fileName;
  StudyMaterialType _materialType = StudyMaterialType.note;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (kIsWeb) {
        // Web'de image_picker çalışmaz, file_picker kullan
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );
        if (result != null && result.files.single.bytes != null) {
          setState(() {
            _selectedFile = result.files.single;
            _fileName = result.files.single.name;
            _materialType = StudyMaterialType.image;
          });
        }
      } else {
        final XFile? image = await _imagePicker.pickImage(source: source);
        if (image != null) {
          setState(() {
            _selectedFile = File(image.path);
            _fileName = image.name;
            _materialType = StudyMaterialType.image;
          });
        }
      }
    } catch (e) {
      _showError('Resim seçilirken hata oluştu: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', // Dokümanlar
          'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic', 'heif', // Resimler
        ],
      );

      if (result != null) {
        final extension = result.files.single.extension?.toLowerCase() ?? '';
        
        setState(() {
          if (kIsWeb) {
            // Web'de PlatformFile kullan
            _selectedFile = result.files.single;
          } else {
            // Mobilde File kullan
            if (result.files.single.path != null) {
              _selectedFile = File(result.files.single.path!);
            } else {
              _showError('Dosya yolu alınamadı');
              return;
            }
          }
          _fileName = result.files.single.name;
          
          // Dosya türünü otomatik belirle
          if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic', 'heif'].contains(extension)) {
            _materialType = StudyMaterialType.image;
          } else if (extension == 'pdf') {
            _materialType = StudyMaterialType.pdf;
          } else {
            // Eğer PDF veya resim değilse, genel bir not olarak kabul et
            _materialType = StudyMaterialType.note;
          }
        });
      }
    } catch (e) {
      _showError('Dosya seçilirken hata oluştu: $e');
    }
  }

  Future<void> _uploadMaterial() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      _showError('Lütfen bir dosya seçin');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Upload file to Firebase Storage
      final fileUrl = await _storageService.uploadStudyMaterial(
        _selectedFile!,
        widget.course.studentId,
        widget.course.id,
      );

      // Create study material document
      final material = StudyMaterial(
        id: '',
        courseId: widget.course.id,
        studentId: widget.course.studentId,
        title: _titleController.text.trim(),
        type: _materialType,
        fileUrl: fileUrl,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        uploadedAt: DateTime.now(),
      );

      final materialId = await _firestoreService.addStudyMaterial(material);

      // AI analizi yap (GERÇEK DOSYA İÇERİĞİ ile!)
      if (kIsWeb) {
        // Web'de PlatformFile kullan
        final platformFile = _selectedFile as PlatformFile;
        _performAIAnalysis(
          materialId, 
          fileBytes: platformFile.bytes,
          fileName: platformFile.name,
        );
      } else {
        // Mobilde File path kullan
        _performAIAnalysis(materialId, filePath: (_selectedFile as File).path);
      }

      // Update course file count
      await _firestoreService.updateCourse(
        widget.course.id,
        {'uploadedFilesCount': widget.course.uploadedFilesCount + 1},
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Materyal yüklendi. AI analizi devam ediyor...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showError('Yükleme sırasında hata oluştu: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _performAIAnalysis(
    String materialId, {
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        print('🎓 ÖĞRETMEN STİLİ ANALİZİ başlatılıyor (Deneme ${retryCount + 1}/$maxRetries)...');
        if (kIsWeb) {
          print('📁 Web dosyası: $fileName');
        } else {
          print('📁 Dosya yolu: $filePath');
        }
        
        // ✅ CORRECT: Use teacher style analysis
        final analysisResult = await _teacherAnalyzer.analyzeDocumentForTeacherStyle(
          filePath: filePath,
          fileBytes: fileBytes,
          fileName: fileName,
          courseName: widget.course.name,
          documentTitle: _titleController.text,
          teacherName: widget.course.teacherName ?? 'Öğretmen',
          documentId: materialId,
        );

        // Convert DocumentAnalysis to JSON string for Firestore
        final analysisJson = json.encode({
          'documentType': analysisResult.documentType,
          'mainTopic': analysisResult.mainTopic,
          'subTopics': analysisResult.subTopics,
          'topicDepth': analysisResult.topicDepth,
          'questions': analysisResult.questions.map((q) => {
            'questionNumber': q.questionNumber,
            'type': q.type,
            'difficulty': q.difficulty,
            'topic': q.topic,
            'pageNumber': q.pageNumber,
            'preview': q.preview,
          }).toList(),
          'teacherStyleInsights': {
            'emphasizedTopics': analysisResult.teacherStyleInsights.emphasizedTopics,
            'preferredQuestionTypes': analysisResult.teacherStyleInsights.preferredQuestionTypes,
            'difficultyPreference': analysisResult.teacherStyleInsights.difficultyPreference,
            'usesVisuals': analysisResult.teacherStyleInsights.usesVisuals,
            'usesRealLifeExamples': analysisResult.teacherStyleInsights.usesRealLifeExamples,
            'focusOnMemorization': analysisResult.teacherStyleInsights.focusOnMemorization,
            'additionalNotes': analysisResult.teacherStyleInsights.additionalNotes,
          },
          'examPredictionHints': {
            'likelyQuestionCount': analysisResult.examPredictionHints.likelyQuestionCount,
            'confidence': analysisResult.examPredictionHints.confidence,
            'reasoning': analysisResult.examPredictionHints.reasoning,
          },
          'analyzedAt': analysisResult.analyzedAt.toIso8601String(),
        });

        // Save structured JSON to Firestore
        await _firestoreService.updateMaterialAnalysis(materialId, analysisJson);
        
        print('✅ ÖĞRETMEN STİLİ ANALİZİ tamamlandı: ${analysisResult.questions.length} soru bulundu');
        
        // PHASE 2.2: Trigger automatic teacher profile update
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            print('🎓 Otomatik öğretmen profili güncelleniyor...');
            await _automaticProfileService.onMaterialUploaded(
              materialId: materialId,
              courseId: widget.course.id,
              studentId: currentUser.uid,
              filePath: filePath ?? '',
              courseName: widget.course.name,
              teacherName: widget.course.teacherName ?? 'Öğretmen',
              documentTitle: _titleController.text.trim(),
            );
            print('✅ Otomatik profil güncelleme başlatıldı');
          }
        } catch (e) {
          print('⚠️ Otomatik profil güncelleme hatası (devam ediliyor): $e');
          // Don't fail the whole process if profile update fails
        }
        
        return; // Success, exit loop
        
      } catch (e) {
        retryCount++;
        print('❌ Öğretmen stili analiz hatası (Deneme $retryCount): $e');
        
        if (retryCount >= maxRetries) {
          print('⚠️ Analiz $maxRetries denemeden sonra başarısız oldu');
          // Save error message
          await _firestoreService.updateMaterialAnalysis(
            materialId,
            json.encode({
              'error': true,
              'message': 'Dosya analiz edilemedi: $e',
              'timestamp': DateTime.now().toIso8601String(),
            })
          );
          return;
        }
        
        // Wait before retry
        await Future.delayed(Duration(seconds: 2 * retryCount));
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materyal Yükle'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Upload area
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 64,
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedFile == null)
                        Text(
                          'Dosya Seçin',
                          style: Theme.of(context).textTheme.displaySmall,
                        )
                      else
                        Column(
                          children: [
                            Icon(
                              _materialType == StudyMaterialType.image
                                  ? Icons.image
                                  : Icons.picture_as_pdf,
                              size: 48,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _fileName ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeri'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Kamera'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickDocument,
                    icon: const Icon(Icons.description),
                    label: const Text('Dosya Seç (PDF/Resim)'),
                  ),
                ),
                const SizedBox(height: 8),
                // Desteklenen formatlar bilgisi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Desteklenen formatlar: JPG, PNG, WEBP, GIF, BMP, HEIC, PDF',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık *',
                    hintText: 'Örn: Ders Notu - Bölüm 3',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Başlık gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Description field
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama (Opsiyonel)',
                    hintText: 'Materyal hakkında notlar...',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),
                // Upload button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadMaterial,
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Yükle & Analiz Et'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

