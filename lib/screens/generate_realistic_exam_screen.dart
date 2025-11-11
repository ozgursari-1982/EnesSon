import 'package:flutter/material.dart';
import '../models/teacher_style_profile.dart';
import '../services/teacher_style_analyzer.dart';
import '../models/test.dart';

/// PHASE 2.1: Screen for generating realistic exams based on teacher profile
class GenerateRealisticExamScreen extends StatefulWidget {
  final TeacherStyleProfile profile;
  final String courseName;

  const GenerateRealisticExamScreen({
    Key? key,
    required this.profile,
    required this.courseName,
  }) : super(key: key);

  @override
  State<GenerateRealisticExamScreen> createState() => _GenerateRealisticExamScreenState();
}

class _GenerateRealisticExamScreenState extends State<GenerateRealisticExamScreen> {
  final TeacherStyleAnalyzer _analyzer = TeacherStyleAnalyzer();
  int _questionCount = 10;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerçekçi Sınav Oluştur'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile summary card
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school, color: Colors.green, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.profile.teacherName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.courseName,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Öğretmen Stili:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.profile.teacherPersonality,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow('Analiz Edilen Belge', '${widget.profile.totalDocumentsAnalyzed}'),
                    _buildStatRow('Bulunan Soru', '${widget.profile.totalQuestionsFound}'),
                    _buildStatRow(
                      'Tahmin Güvenilirliği',
                      '%${(widget.profile.examPrediction.overallConfidence * 100).toInt()}',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Question count selector
            const Text(
              'Soru Sayısı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _questionCount.toDouble(),
              min: 5,
              max: 20,
              divisions: 15,
              label: '$_questionCount soru',
              onChanged: (value) {
                setState(() {
                  _questionCount = value.round();
                });
              },
            ),
            Text(
              '$_questionCount soru oluşturulacak',
              style: TextStyle(color: Colors.grey[600]),
            ),
            
            const SizedBox(height: 24),
            
            // Critical topics
            if (widget.profile.examPrediction.criticalTopics.isNotEmpty) ...[
              const Text(
                'Kritik Konular',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: widget.profile.examPrediction.criticalTopics
                        .map((topic) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.orange, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(topic)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Generate button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateRealisticExam,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.quiz),
                label: Text(
                  _isGenerating ? 'Sınav Oluşturuluyor...' : 'Gerçekçi Sınav Oluştur',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bu sınav, ${widget.profile.teacherName} öğretmenin soru sorma stiline göre oluşturulacak.',
                      style: TextStyle(color: Colors.blue[900], fontSize: 13),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateRealisticExam() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Generate realistic exam using teacher profile
      final questions = await _analyzer.generateRealisticExam(
        teacherProfile: widget.profile,
        questionCount: _questionCount,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${questions.length} soru başarıyla oluşturuldu!'),
          backgroundColor: Colors.green,
        ),
      );

      // TODO: Navigate to test taking screen with generated questions
      // For now, just show the count
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sınav Hazır!'),
          content: Text(
            '${questions.length} soru oluşturuldu.\n\n'
            'Bu sorular ${widget.profile.teacherName} öğretmenin tarzına göre hazırlandı.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}
