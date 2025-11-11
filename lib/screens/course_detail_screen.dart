import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/study_material.dart';
import '../models/test.dart';
import '../services/firestore_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/gemini_ai_service.dart';
import 'upload_material_screen.dart';
import 'generate_test_screen.dart';
import 'take_test_screen.dart';
import 'material_detail_screen.dart';
import 'test_review_screen.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../services/teacher_style_analyzer.dart';
import '../models/teacher_style_profile.dart';
import 'teacher_analysis_screen.dart';
import '../widgets/teacher_profile_widget.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = FirestoreService();
  final _storageService = FirebaseStorageService();
  final _aiService = GeminiAIService();
  final _teacherAnalyzer = TeacherStyleAnalyzer();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.name),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Materyaller'),
            Tab(text: 'Testler'),
            Tab(text: 'Öğretmen Analizi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMaterialsTab(),
          _buildTestsTab(),
          _buildTeacherAnalysisTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 2 ? null : FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UploadMaterialScreen(course: widget.course),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GenerateTestScreen(course: widget.course),
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Materyal Yükle' : 'Test Oluştur'),
      ),
    );
  }

  Widget _buildMaterialsTab() {
    return StreamBuilder<List<StudyMaterial>>(
      stream: _firestoreService.getCourseMaterials(widget.course.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final materials = snapshot.data ?? [];

        if (materials.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upload_file_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz materyal yüklemediniz',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ders notlarınızı ve ödevlerinizi yükleyin',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final analyzedCount = materials.where((m) => m.aiAnalysis != null).length;
        final totalCount = materials.length;
        final canCreateTest = analyzedCount > 0;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: materials.length + 3, // +1 info kartı, +1 teacher profile widget, +1 test oluştur butonu
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            // İlk item: Info kartı
            if (index == 0) {
              return Card(
                color: analyzedCount == totalCount 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        analyzedCount == totalCount 
                            ? Icons.check_circle 
                            : Icons.hourglass_empty,
                        color: analyzedCount == totalCount 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Analiz Durumu: $analyzedCount/$totalCount',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: analyzedCount == totalCount 
                                    ? Colors.green.shade700 
                                    : Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              analyzedCount == totalCount
                                  ? 'Tüm materyaller analiz edildi. Test oluşturabilirsiniz!'
                                  : 'Bazı materyaller henüz analiz ediliyor...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // İkinci item: Teacher Profile Widget (PHASE 2.1 Integration)
            if (index == 1) {
              return TeacherProfileWidget(
                courseId: widget.course.id,
                courseName: widget.course.name,
              );
            }
            
            // Son item: Test Oluştur butonu
            if (index == materials.length + 2) {
              return Column(
                children: [
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: canCreateTest
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GenerateTestScreen(course: widget.course),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.quiz),
                      label: Text(
                        canCreateTest
                            ? 'AI ile Test Oluştur ($analyzedCount Materyal Hazır)'
                            : 'Test Oluşturmak İçin Materyal Bekliyor...',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canCreateTest
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                      ),
                    ),
                  ),
                  if (!canCreateTest) ...[
                    const SizedBox(height: 8),
                    Text(
                      'AI materyal analizini tamamladıktan sonra test oluşturabilirsiniz',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              );
            }
            
            // Diğer itemler: Materyal kartları
            final material = materials[index - 2]; // -2 because of info card and teacher profile widget
            return _buildMaterialCard(material);
          },
        );
      },
    );
  }

  Widget _buildMaterialCard(StudyMaterial material) {
    IconData icon;
    Color color;

    switch (material.type) {
      case StudyMaterialType.pdf:
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case StudyMaterialType.image:
        icon = Icons.image;
        color = Colors.blue;
        break;
      case StudyMaterialType.note:
        icon = Icons.note;
        color = Colors.green;
        break;
      case StudyMaterialType.homework:
        icon = Icons.assignment;
        color = Colors.orange;
        break;
    }

    return Card(
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MaterialDetailScreen(material: material),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(material.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(material.uploadedAt)),
            const SizedBox(height: 4),
            if (material.aiAnalysis != null)
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    'AI analizi tamamlandı',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'AI analiz ediliyor...',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMaterialMenuAction(value, material),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'reanalyze',
              child: Row(
                children: [
                  Icon(Icons.refresh, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Tekrar Analiz Et'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Sil'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestsTab() {
    return StreamBuilder<List<Test>>(
      stream: _firestoreService.getCourseTests(widget.course.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final tests = snapshot.data ?? [];

        if (tests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz test oluşturmadınız',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI size özel testler hazırlayabilir',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final test = tests[index];
            return _buildTestCard(test);
          },
        );
      },
    );
  }

  Widget _buildTestCard(Test test) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: test.isCompleted
              ? Colors.green.withOpacity(0.2)
              : Theme.of(context).primaryColor.withOpacity(0.2),
          child: Icon(
            test.isCompleted ? Icons.check : Icons.quiz,
            color: test.isCompleted ? Colors.green : Theme.of(context).primaryColor,
          ),
        ),
        title: Text(test.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${test.questions.length} Soru'),
            if (test.isCompleted)
              Text(
                'Puan: ${test.score?.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: test.isCompleted
            ? IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue),
                tooltip: 'Soruları ve Cevapları İncele',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TestReviewScreen(test: test),
                    ),
                  );
                },
              )
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (!test.isCompleted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TakeTestScreen(test: test),
              ),
            );
          } else {
            // Tamamlanmış test için review ekranını aç
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TestReviewScreen(test: test),
              ),
            );
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleMaterialMenuAction(String action, StudyMaterial material) async {
    if (action == 'reanalyze') {
      await _reanalyzeMaterial(material);
    } else if (action == 'delete') {
      await _deleteMaterial(material);
    }
  }

  Future<void> _reanalyzeMaterial(StudyMaterial material) async {
    // Onay iletişim kutusu
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tekrar Analiz Et'),
        content: const Text(
          'Bu materyal AI tarafından tekrar analiz edilecek. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Analiz Et'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('AI analiz ediyor...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Dosyayı geçici olarak indir
      final response = await http.get(Uri.parse(material.fileUrl));
      if (response.statusCode != 200) {
        throw 'Dosya indirilemedi';
      }

      // Geçici dizine kaydet
      final tempDir = await getTemporaryDirectory();
      final extension = material.fileUrl.split('.').last.split('?').first;
      final tempFile = File('${tempDir.path}/temp_material.$extension');
      await tempFile.writeAsBytes(response.bodyBytes);

      // AI analizi yap
      final analysis = await _aiService.analyzeStudyMaterialWithFile(
        filePath: tempFile.path,
        courseName: widget.course.name,
        title: material.title,
        description: material.description,
      );

      // Geçici dosyayı sil
      await tempFile.delete();

      // Analizi kaydet
      await _firestoreService.updateMaterialAnalysis(material.id, analysis);

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Materyal yeniden analiz edildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Analiz hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMaterial(StudyMaterial material) async {
    // Onay iletişim kutusu
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Materyali Sil'),
        content: const Text(
          'Bu materyal kalıcı olarak silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Siliniyor...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Önce Storage'dan dosyayı sil
      await _storageService.deleteFile(material.fileUrl);
      
      // Sonra Firestore'dan kaydı sil
      await _firestoreService.deleteMaterial(material.id);

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Materyal başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Silme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTeacherAnalysisTab() {
    return StreamBuilder<List<StudyMaterial>>(
      stream: _firestoreService.getCourseMaterials(widget.course.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final materials = snapshot.data ?? [];
        final analyzedMaterials = materials.where((m) => m.aiAnalysis != null).toList();

        if (analyzedMaterials.length < 3) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    'Öğretmen Analizi',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Öğretmeninizin sınav stilini analiz etmek için en az 3 materyal yüklemeniz gerekiyor.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value: analyzedMaterials.length / 3,
                    backgroundColor: Colors.grey[200],
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${analyzedMaterials.length}/3 materyal analiz edildi',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      _tabController.animateTo(0);
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Materyal Yükle'),
                  ),
                ],
              ),
            ),
          );
        }

        return FutureBuilder<TeacherStyleProfile?>(
          future: _teacherAnalyzer.buildTeacherProfile(
            courseId: widget.course.id,
            studentId: widget.course.studentId,
            courseName: widget.course.name,
            teacherName: widget.course.teacherName ?? 'Öğretmen',
          ),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('AI öğretmen profilini oluşturuyor...'),
                  ],
                ),
              );
            }

            if (profileSnapshot.hasError || profileSnapshot.data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Profil oluşturulamadı',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${profileSnapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            return TeacherAnalysisScreen(profile: profileSnapshot.data!);
          },
        );
      },
    );
  }
}

