import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/gamification_service.dart';
import '../screens/achievements_screen.dart';
import '../screens/leaderboard_screen.dart';

/// Kullanıcı İstatistikleri ve Ödül Widget'ı (Dashboard için)
class UserStatsWidget extends StatelessWidget {
  final String userId;

  const UserStatsWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gamificationService = GamificationService();

    return StreamBuilder<UserStats?>(
      stream: gamificationService.getUserStatsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        return _buildStatsCard(context, stats);
      },
    );
  }

  Widget _buildStatsCard(BuildContext context, UserStats stats) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve rütbe
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.rankTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seviye ${stats.level}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stats.totalPoints}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Seviye progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Seviye İlerlemesi',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${stats.currentLevelPoints}/${stats.nextLevelPoints}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: stats.levelProgress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // İstatistikler
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    icon: Icons.local_fire_department,
                    value: '${stats.currentStreak}',
                    label: 'Gün',
                  ),
                  _buildStatColumn(
                    icon: Icons.emoji_events,
                    value: '${stats.totalAchievements}',
                    label: 'Başarı',
                  ),
                  _buildStatColumn(
                    icon: Icons.access_time,
                    value: '${(stats.totalStudyTimeMinutes / 60).toStringAsFixed(1)}',
                    label: 'Saat',
                  ),
                  _buildStatColumn(
                    icon: Icons.quiz,
                    value: '${stats.testsCompleted}',
                    label: 'Test',
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AchievementsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.emoji_events),
                      label: const Text('Başarılarım'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LeaderboardScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.leaderboard),
                      label: const Text('Sıralama'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Başarı Kazanıldı Bildirim Dialog'u
class AchievementUnlockedDialog extends StatelessWidget {
  final Achievement achievement;

  const AchievementUnlockedDialog({
    Key? key,
    required this.achievement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getTierGradient(achievement.tier),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animasyonlu icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconData(achievement.iconName),
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Başarı Kazanıldı!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    color: _getTierColor(achievement.tier),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${achievement.points} Puan',
                    style: TextStyle(
                      color: _getTierColor(achievement.tier),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _getTierColor(achievement.tier),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Harika!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
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

/// Başarı kazanıldığında göster
void showAchievementDialog(BuildContext context, Achievement achievement) {
  showDialog(
    context: context,
    builder: (context) => AchievementUnlockedDialog(
      achievement: achievement,
    ),
  );
}
