import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

/// PHASE 3.3: Profile completion gamification widget
/// Encourages users to complete their profile with progress tracking and motivation
class ProfileCompletionWidget extends StatelessWidget {
  const ProfileCompletionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();
        
        // Calculate completion
        final completion = _calculateCompletion(data);
        
        // Don't show if already complete
        if (completion.percentage >= 100) return const SizedBox.shrink();
        
        return _buildCompletionCard(context, completion);
      },
    );
  }

  ProfileCompletion _calculateCompletion(Map<String, dynamic> data) {
    final items = <CompletionItem>[];
    int completed = 0;
    
    // Check profile fields
    if (data['photoUrl'] != null && (data['photoUrl'] as String).isNotEmpty) {
      items.add(CompletionItem(
        title: 'Profil Fotoğrafı',
        icon: Icons.account_circle,
        completed: true,
        points: 10,
      ));
      completed++;
    } else {
      items.add(CompletionItem(
        title: 'Profil Fotoğrafı Ekle',
        icon: Icons.account_circle_outlined,
        completed: false,
        points: 10,
        action: 'Profil sayfasından fotoğraf ekle',
      ));
    }
    
    // Check if student has courses
    final coursesCount = data['coursesCount'] ?? 0;
    if (coursesCount > 0) {
      items.add(CompletionItem(
        title: '$coursesCount Ders Eklendi',
        icon: Icons.school,
        completed: true,
        points: 15,
      ));
      completed++;
    } else {
      items.add(CompletionItem(
        title: 'İlk Dersini Ekle',
        icon: Icons.school_outlined,
        completed: false,
        points: 15,
        action: 'Ders ekle butonuna tıkla',
      ));
    }
    
    // Check if student uploaded materials
    final materialsCount = data['materialsCount'] ?? 0;
    if (materialsCount >= 3) {
      items.add(CompletionItem(
        title: '$materialsCount Materyal Yüklendi',
        icon: Icons.upload_file,
        completed: true,
        points: 20,
      ));
      completed++;
    } else if (materialsCount > 0) {
      items.add(CompletionItem(
        title: 'Daha ${3 - materialsCount} Materyal Yükle',
        icon: Icons.upload_file_outlined,
        completed: false,
        points: 20,
        action: '${3 - materialsCount} materyal daha yükle',
      ));
    } else {
      items.add(CompletionItem(
        title: 'İlk Materyalini Yükle',
        icon: Icons.upload_file_outlined,
        completed: false,
        points: 20,
        action: 'Ders notunu veya ödevini yükle',
      ));
    }
    
    // Check if student completed tests
    final testsCompleted = data['testsCompleted'] ?? 0;
    if (testsCompleted >= 1) {
      items.add(CompletionItem(
        title: '$testsCompleted Test Tamamlandı',
        icon: Icons.quiz,
        completed: true,
        points: 15,
      ));
      completed++;
    } else {
      items.add(CompletionItem(
        title: 'İlk Testini Çöz',
        icon: Icons.quiz_outlined,
        completed: false,
        points: 15,
        action: 'AI ile test oluştur ve çöz',
      ));
    }
    
    // Check exam date
    final hasExamDate = data['hasExamDate'] ?? false;
    if (hasExamDate) {
      items.add(CompletionItem(
        title: 'Sınav Tarihi Belirlendi',
        icon: Icons.event,
        completed: true,
        points: 10,
      ));
      completed++;
    } else {
      items.add(CompletionItem(
        title: 'Sınav Tarihini Belirle',
        icon: Icons.event_outlined,
        completed: false,
        points: 10,
        action: 'Derslerinde sınav tarihi ekle',
      ));
    }
    
    final total = items.length;
    final percentage = ((completed / total) * 100).toInt();
    final totalPoints = items.fold<int>(0, (sum, item) => sum + item.points);
    final earnedPoints = items.where((i) => i.completed).fold<int>(0, (sum, item) => sum + item.points);
    
    return ProfileCompletion(
      items: items,
      completedCount: completed,
      totalCount: total,
      percentage: percentage,
      earnedPoints: earnedPoints,
      totalPoints: totalPoints,
    );
  }

  Widget _buildCompletionCard(BuildContext context, ProfileCompletion completion) {
    return Card(
      elevation: 2,
      color: Colors.purple[50],
      margin: const EdgeInsets.all(16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple,
          child: Text(
            '${completion.percentage}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: const Text(
          '🎯 Profil Tamamlama',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: completion.percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              minHeight: 6,
            ),
            const SizedBox(height: 4),
            Text(
              '${completion.earnedPoints}/${completion.totalPoints} puan • ${completion.completedCount}/${completion.totalCount} görev',
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Motivation message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.purple, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getMotivationMessage(completion.percentage),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Completion items
                ...completion.items.map((item) => _buildCompletionItem(item)),
                
                // Bonus message
                if (completion.percentage >= 80) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.celebration, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '🎉 Harika! Neredeyse tamamladın! AI öğretmen tam performansta çalışacak!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[900],
                              fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }

  Widget _buildCompletionItem(CompletionItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            item.icon,
            color: item.completed ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    decoration: item.completed ? TextDecoration.lineThrough : null,
                    color: item.completed ? Colors.green[700] : Colors.black87,
                  ),
                ),
                if (!item.completed && item.action != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.action!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: item.completed ? Colors.green[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${item.points}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: item.completed ? Colors.green[700] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationMessage(int percentage) {
    if (percentage >= 80) {
      return '🌟 Mükemmel! Profilini tamamlamak üzeresin!';
    } else if (percentage >= 60) {
      return '💪 Harika gidiyorsun! Biraz daha!';
    } else if (percentage >= 40) {
      return '👍 İyi bir başlangıç! Devam et!';
    } else if (percentage >= 20) {
      return '🚀 Başladın! Hadi tamamlayalım!';
    } else {
      return '✨ Profilini tamamla, AI öğretmen seni daha iyi tanısın!';
    }
  }
}

/// Profile completion data
class ProfileCompletion {
  final List<CompletionItem> items;
  final int completedCount;
  final int totalCount;
  final int percentage;
  final int earnedPoints;
  final int totalPoints;

  ProfileCompletion({
    required this.items,
    required this.completedCount,
    required this.totalCount,
    required this.percentage,
    required this.earnedPoints,
    required this.totalPoints,
  });
}

/// Individual completion item
class CompletionItem {
  final String title;
  final IconData icon;
  final bool completed;
  final int points;
  final String? action;

  CompletionItem({
    required this.title,
    required this.icon,
    required this.completed,
    required this.points,
    this.action,
  });
}
