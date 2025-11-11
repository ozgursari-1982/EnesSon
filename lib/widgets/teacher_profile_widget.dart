import 'package:flutter/material.dart';
import '../services/automatic_teacher_profile_service.dart';
import '../models/teacher_style_profile.dart';
import '../screens/generate_realistic_exam_screen.dart';

/// PHASE 2.1: Teacher Profile Status Widget
/// Shows profile building progress or ready status
class TeacherProfileWidget extends StatefulWidget {
  final String courseId;
  final String courseName;

  const TeacherProfileWidget({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  State<TeacherProfileWidget> createState() => _TeacherProfileWidgetState();
}

class _TeacherProfileWidgetState extends State<TeacherProfileWidget> {
  final AutomaticTeacherProfileService _service = AutomaticTeacherProfileService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileStatus>(
      future: _service.getProfileStatus(widget.courseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        final status = snapshot.data!;
        
        if (status.isReady) {
          return _buildReadyProfile(context, status.profile!);
        } else {
          return _buildProgressCard(context, status);
        }
      },
    );
  }

  /// Profile is ready - show full card with action button
  Widget _buildReadyProfile(BuildContext context, TeacherStyleProfile profile) {
    return Card(
      elevation: 4,
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
                        '🎓 ${profile.teacherName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Öğretmen Profili Hazır!',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildStatRow(Icons.quiz, '${profile.totalQuestionsFound} soru analiz edildi'),
            _buildStatRow(Icons.book, '${profile.totalDocumentsAnalyzed} belge incelendi'),
            _buildStatRow(
              Icons.stars,
              'Sınav Tahmini: %${(profile.examPrediction.overallConfidence * 100).toInt()}',
            ),
            
            const SizedBox(height: 16),
            
            // Teacher personality summary
            if (profile.teacherPersonality.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Öğretmen Stili:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.teacherPersonality,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            
            ElevatedButton.icon(
              onPressed: () => _generateRealisticExam(context, profile),
              icon: const Icon(Icons.quiz_outlined),
              label: const Text('Gerçekçi Sınav Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Profile not ready yet - show progress
  Widget _buildProgressCard(BuildContext context, ProfileStatus status) {
    final progress = status.progress.clamp(0.0, 1.0);
    
    return Card(
      elevation: 2,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔍 Öğretmen Stili Öğreniliyor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        status.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            
            Text(
              '${status.analysisCount}/3 belge analiz edildi',
              style: const TextStyle(fontSize: 13),
            ),
            
            if (status.remainingCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '💡 ${status.remainingCount} belge daha yükleyince öğretmenin soru sorma stilini öğreneceğim!',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green[700]),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _generateRealisticExam(BuildContext context, TeacherStyleProfile profile) {
    // Check if screen exists, if not show a message
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GenerateRealisticExamScreen(
            profile: profile,
            courseName: widget.courseName,
          ),
        ),
      );
    } catch (e) {
      // If screen doesn't exist yet, show a placeholder message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gerçekçi sınav ekranı yakında eklenecek!'),
        ),
      );
    }
  }
}
