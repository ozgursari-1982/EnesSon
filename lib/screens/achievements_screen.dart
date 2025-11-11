import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/gamification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Başarılar Ekranı
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final GamificationService _gamificationService = GamificationService();
  late String _userId;
  bool _isLoading = true;

  List<Achievement> _allAchievements = [];
  List<UserAchievement> _userAchievements = [];
  UserStats? _userStats;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser!.uid;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _allAchievements = await _gamificationService.getAllAchievements();
    _userAchievements = await _gamificationService.getUserAchievements(_userId);
    _userStats = await _gamificationService.getUserStats(_userId);
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Başarılarım'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_userStats == null) {
      return const Center(child: Text('Veri yüklenemedi'));
    }

    // Başarıları kategorilere göre grupla
    final groupedAchievements = <AchievementCategory, List<Achievement>>{};
    for (final achievement in _allAchievements) {
      groupedAchievements.putIfAbsent(achievement.category, () => []);
      groupedAchievements[achievement.category]!.add(achievement);
    }

    return Column(
      children: [
        // İstatistik özeti
        _buildStatsCard(),
        const SizedBox(height: 8),
        
        // Başarı listesi
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final category in groupedAchievements.keys)
                _buildCategorySection(
                  category,
                  groupedAchievements[category]!,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final unlocked = _userAchievements.where((a) => a.isUnlocked).length;
    final total = _allAchievements.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[700]!, Colors.purple[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.emoji_events,
            label: 'Kazanılan',
            value: '$unlocked/$total',
          ),
          Container(width: 1, height: 50, color: Colors.white30),
          _buildStatItem(
            icon: Icons.star,
            label: 'Toplam Puan',
            value: '${_userStats!.totalPoints}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    AchievementCategory category,
    List<Achievement> achievements,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 16),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                _getCategoryTitle(category),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...achievements.map((achievement) => _buildAchievementCard(achievement)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final userAchievement = _userAchievements.firstWhere(
      (ua) => ua.achievementId == achievement.id,
      orElse: () => UserAchievement(
        achievementId: achievement.id,
        unlockedAt: DateTime.now(),
        progress: 0,
      ),
    );

    final isUnlocked = userAchievement.isUnlocked;
    final progress = userAchievement.progress / achievement.requiredValue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnlocked ? 4 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isUnlocked
              ? LinearGradient(
                  colors: _getTierGradient(achievement.tier),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(achievement.iconName),
                  size: 32,
                  color: isUnlocked ? Colors.white : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              
              // İçerik
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUnlocked
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // İlerleme
                    if (!isUnlocked) ...[
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${userAchievement.progress}/${achievement.requiredValue}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Kazanıldı • ${achievement.points} puan',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Seviye rozeti
              if (isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getTierName(achievement.tier),
                    style: TextStyle(
                      color: _getTierColor(achievement.tier),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.materialUpload:
        return Icons.upload_file;
      case AchievementCategory.testCompletion:
        return Icons.quiz;
      case AchievementCategory.studyTime:
        return Icons.access_time;
      case AchievementCategory.streak:
        return Icons.local_fire_department;
      case AchievementCategory.perfectScore:
        return Icons.stars;
      case AchievementCategory.improvement:
        return Icons.trending_up;
      default:
        return Icons.emoji_events;
    }
  }

  String _getCategoryTitle(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.materialUpload:
        return 'Materyal Yükleme';
      case AchievementCategory.testCompletion:
        return 'Test Çözme';
      case AchievementCategory.studyTime:
        return 'Çalışma Süresi';
      case AchievementCategory.streak:
        return 'Ardışık Günler';
      case AchievementCategory.perfectScore:
        return 'Tam Puanlar';
      case AchievementCategory.improvement:
        return 'Gelişim';
      default:
        return 'Diğer';
    }
  }

  IconData _getIconData(String iconName) {
    // Material Icons mapping
    final iconMap = {
      'upload': Icons.upload,
      'folder': Icons.folder,
      'library_books': Icons.library_books,
      'archive': Icons.archive,
      'quiz': Icons.quiz,
      'school': Icons.school,
      'workspace_premium': Icons.workspace_premium,
      'emoji_events': Icons.emoji_events,
      'schedule': Icons.schedule,
      'timer': Icons.timer,
      'hourglass_full': Icons.hourglass_full,
      'star_rate': Icons.star_rate,
      'local_fire_department': Icons.local_fire_department,
      'whatshot': Icons.whatshot,
      'stars': Icons.stars,
      'military_tech': Icons.military_tech,
      'grade': Icons.grade,
      'verified': Icons.verified,
      'diamond': Icons.diamond,
      'trending_up': Icons.trending_up,
      'arrow_circle_up': Icons.arrow_circle_up,
      'auto_awesome': Icons.auto_awesome,
    };
    
    return iconMap[iconName] ?? Icons.star;
  }

  String _getTierName(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return 'Bronz';
      case AchievementTier.silver:
        return 'Gümüş';
      case AchievementTier.gold:
        return 'Altın';
      case AchievementTier.platinum:
        return 'Platin';
      case AchievementTier.diamond:
        return 'Elmas';
    }
  }

  Color _getTierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return Colors.brown[700]!;
      case AchievementTier.silver:
        return Colors.grey[700]!;
      case AchievementTier.gold:
        return Colors.amber[700]!;
      case AchievementTier.platinum:
        return Colors.cyan[700]!;
      case AchievementTier.diamond:
        return Colors.blue[700]!;
    }
  }

  List<Color> _getTierGradient(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return [Colors.brown[600]!, Colors.brown[400]!];
      case AchievementTier.silver:
        return [Colors.grey[600]!, Colors.grey[400]!];
      case AchievementTier.gold:
        return [Colors.amber[700]!, Colors.amber[500]!];
      case AchievementTier.platinum:
        return [Colors.cyan[700]!, Colors.cyan[500]!];
      case AchievementTier.diamond:
        return [Colors.blue[700]!, Colors.purple[500]!];
    }
  }
}
