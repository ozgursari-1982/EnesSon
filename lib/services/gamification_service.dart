import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/achievement.dart';

/// Gamification ve Başarı Sistemi Servisi
class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection referansları
  CollectionReference get _userStatsCollection =>
      _firestore.collection('userStats');
  CollectionReference get _achievementsCollection =>
      _firestore.collection('achievements');
  CollectionReference get _userAchievementsCollection =>
      _firestore.collection('userAchievements');

  /// Tüm başarıları getir
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final snapshot = await _achievementsCollection.get();
      return snapshot.docs
          .map((doc) => Achievement.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Başarılar yüklenirken hata: $e');
      return [];
    }
  }

  /// Kullanıcının başarılarını getir
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    try {
      final snapshot = await _userAchievementsCollection
          .doc(userId)
          .collection('achievements')
          .get();
      
      return snapshot.docs
          .map((doc) => UserAchievement.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Kullanıcı başarıları yüklenirken hata: $e');
      return [];
    }
  }

  /// Kullanıcı istatistiklerini getir
  Future<UserStats?> getUserStats(String userId) async {
    try {
      final doc = await _userStatsCollection.doc(userId).get();
      if (!doc.exists) {
        // İlk kez - yeni istatistik oluştur
        final newStats = UserStats(
          userId: userId,
          lastActivityDate: DateTime.now(),
        );
        await _userStatsCollection.doc(userId).set(newStats.toMap());
        return newStats;
      }
      return UserStats.fromMap(doc.data() as Map<String, dynamic>, userId);
    } catch (e) {
      print('Kullanıcı istatistikleri yüklenirken hata: $e');
      return null;
    }
  }

  /// Kullanıcı istatistiklerini stream olarak getir
  Stream<UserStats?> getUserStatsStream(String userId) {
    return _userStatsCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserStats.fromMap(doc.data() as Map<String, dynamic>, userId);
    });
  }

  /// Materyal yüklendiğinde çağrılır
  Future<List<Achievement>> onMaterialUploaded(String userId) async {
    final stats = await getUserStats(userId);
    if (stats == null) return [];

    // İstatistikleri güncelle
    final newMaterialCount = stats.materialsUploaded + 1;
    final points = _calculateMaterialPoints(newMaterialCount);
    
    final updatedStats = stats.copyWith(
      materialsUploaded: newMaterialCount,
      totalPoints: stats.totalPoints + points,
      lastActivityDate: DateTime.now(),
    );

    // Seviye kontrolü
    final leveledUpStats = await _checkAndUpdateLevel(updatedStats);
    
    // Streak kontrolü
    final streakStats = await _updateStreak(leveledUpStats);
    
    // Firestore'a kaydet
    await _userStatsCollection.doc(userId).set(streakStats.toMap());

    // Başarı kontrolü ve kazanma
    return await _checkAndUnlockAchievements(
      userId,
      streakStats,
      AchievementCategory.materialUpload,
    );
  }

  /// Test tamamlandığında çağrılır
  Future<List<Achievement>> onTestCompleted(
    String userId, {
    required double score,
    required int studyTimeMinutes,
  }) async {
    final stats = await getUserStats(userId);
    if (stats == null) return [];

    final isPerfect = score >= 100.0;
    final testPoints = _calculateTestPoints(score);
    final timePoints = _calculateStudyTimePoints(studyTimeMinutes);

    final updatedStats = stats.copyWith(
      testsCompleted: stats.testsCompleted + 1,
      totalStudyTimeMinutes: stats.totalStudyTimeMinutes + studyTimeMinutes,
      perfectScores: isPerfect ? stats.perfectScores + 1 : stats.perfectScores,
      totalPoints: stats.totalPoints + testPoints + timePoints,
      lastActivityDate: DateTime.now(),
    );

    // Seviye ve streak kontrolü
    final leveledUpStats = await _checkAndUpdateLevel(updatedStats);
    final streakStats = await _updateStreak(leveledUpStats);
    
    await _userStatsCollection.doc(userId).set(streakStats.toMap());

    // Başarı kontrolü
    final testAchievements = await _checkAndUnlockAchievements(
      userId,
      streakStats,
      AchievementCategory.testCompletion,
    );

    final studyTimeAchievements = await _checkAndUnlockAchievements(
      userId,
      streakStats,
      AchievementCategory.studyTime,
    );

    final perfectAchievements = isPerfect
        ? await _checkAndUnlockAchievements(
            userId,
            streakStats,
            AchievementCategory.perfectScore,
          )
        : <Achievement>[];

    return [...testAchievements, ...studyTimeAchievements, ...perfectAchievements];
  }

  /// Çalışma süresi eklendiğinde çağrılır
  Future<void> addStudyTime(String userId, int minutes) async {
    final stats = await getUserStats(userId);
    if (stats == null) return;

    final points = _calculateStudyTimePoints(minutes);
    final updatedStats = stats.copyWith(
      totalStudyTimeMinutes: stats.totalStudyTimeMinutes + minutes,
      totalPoints: stats.totalPoints + points,
      lastActivityDate: DateTime.now(),
    );

    final leveledUpStats = await _checkAndUpdateLevel(updatedStats);
    await _userStatsCollection.doc(userId).set(leveledUpStats.toMap());
  }

  /// Puan hesaplama fonksiyonları
  int _calculateMaterialPoints(int count) {
    // İlk 10 materyal: 10 puan
    // 11-50: 15 puan
    // 50+: 20 puan
    if (count <= 10) return 10;
    if (count <= 50) return 15;
    return 20;
  }

  int _calculateTestPoints(double score) {
    // %0-50: 5 puan
    // %51-75: 10 puan
    // %76-90: 15 puan
    // %91-99: 20 puan
    // %100: 30 puan
    if (score < 50) return 5;
    if (score < 75) return 10;
    if (score < 90) return 15;
    if (score < 100) return 20;
    return 30;
  }

  int _calculateStudyTimePoints(int minutes) {
    // Her 10 dakika için 1 puan
    return (minutes / 10).floor();
  }

  /// Seviye kontrolü ve güncelleme
  Future<UserStats> _checkAndUpdateLevel(UserStats stats) async {
    int newLevel = stats.level;
    int currentPoints = stats.currentLevelPoints + stats.totalPoints - (stats.totalPoints - stats.currentLevelPoints);
    int nextLevelPoints = stats.nextLevelPoints;

    // Seviye atlama kontrolü
    while (currentPoints >= nextLevelPoints) {
      newLevel++;
      currentPoints -= nextLevelPoints;
      nextLevelPoints = _calculateNextLevelPoints(newLevel);
    }

    // Rütbe belirleme
    final rankTitle = _getRankTitle(newLevel);

    return stats.copyWith(
      level: newLevel,
      currentLevelPoints: currentPoints,
      nextLevelPoints: nextLevelPoints,
      rankTitle: rankTitle,
    );
  }

  /// Sonraki seviye için gereken puan
  int _calculateNextLevelPoints(int level) {
    // Her seviye %20 daha fazla puan gerektirir
    return (100 * (1.2 * level)).round();
  }

  /// Rütbe belirleme
  String _getRankTitle(int level) {
    if (level < 5) return 'Yeni Başlayan';
    if (level < 10) return 'Çömez';
    if (level < 20) return 'Öğrenci';
    if (level < 30) return 'Çalışkan';
    if (level < 40) return 'Başarılı';
    if (level < 50) return 'Uzman';
    if (level < 75) return 'Usta';
    if (level < 100) return 'Dehâ';
    return 'Efsane';
  }

  /// Streak (ardışık gün) güncelleme
  Future<UserStats> _updateStreak(UserStats stats) async {
    final now = DateTime.now();
    final lastDate = stats.lastActivityDate;
    final daysDiff = now.difference(lastDate).inDays;

    int newStreak = stats.currentStreak;
    int newLongest = stats.longestStreak;

    if (daysDiff == 0) {
      // Aynı gün - değişiklik yok
      newStreak = stats.currentStreak;
    } else if (daysDiff == 1) {
      // Ardışık gün - streak devam ediyor
      newStreak = stats.currentStreak + 1;
    } else {
      // Streak kırıldı - sıfırla
      newStreak = 1;
    }

    // En uzun streak kontrolü
    if (newStreak > newLongest) {
      newLongest = newStreak;
    }

    return stats.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastActivityDate: now,
    );
  }

  /// Başarıları kontrol et ve kilidi aç
  Future<List<Achievement>> _checkAndUnlockAchievements(
    String userId,
    UserStats stats,
    AchievementCategory category,
  ) async {
    final allAchievements = await getAllAchievements();
    final userAchievements = await getUserAchievements(userId);
    
    // İlgili kategorideki başarıları filtrele
    final categoryAchievements = allAchievements
        .where((a) => a.category == category)
        .toList();

    final unlockedAchievements = <Achievement>[];

    for (final achievement in categoryAchievements) {
      // Zaten kazanılmış mı kontrol et
      final userAch = userAchievements.firstWhere(
        (ua) => ua.achievementId == achievement.id,
        orElse: () => UserAchievement(
          achievementId: achievement.id,
          unlockedAt: DateTime.now(),
          progress: 0,
        ),
      );

      if (userAch.isUnlocked) continue;

      // İlerleme hesapla
      final currentProgress = _calculateProgress(stats, achievement.category);
      
      // Başarı kazanıldı mı?
      if (currentProgress >= achievement.requiredValue) {
        await _unlockAchievement(userId, achievement, stats);
        unlockedAchievements.add(achievement);
      } else {
        // İlerleme güncelle
        await _updateAchievementProgress(userId, achievement.id, currentProgress);
      }
    }

    return unlockedAchievements;
  }

  /// Kategoriye göre ilerleme hesapla
  int _calculateProgress(UserStats stats, AchievementCategory category) {
    switch (category) {
      case AchievementCategory.materialUpload:
        return stats.materialsUploaded;
      case AchievementCategory.testCompletion:
        return stats.testsCompleted;
      case AchievementCategory.studyTime:
        return stats.totalStudyTimeMinutes;
      case AchievementCategory.streak:
        return stats.currentStreak;
      case AchievementCategory.perfectScore:
        return stats.perfectScores;
      case AchievementCategory.improvement:
        return stats.level;
      default:
        return 0;
    }
  }

  /// Başarının kilidini aç
  Future<void> _unlockAchievement(
    String userId,
    Achievement achievement,
    UserStats stats,
  ) async {
    final userAchievement = UserAchievement(
      achievementId: achievement.id,
      unlockedAt: DateTime.now(),
      progress: achievement.requiredValue,
      isUnlocked: true,
    );

    await _userAchievementsCollection
        .doc(userId)
        .collection('achievements')
        .doc(achievement.id)
        .set(userAchievement.toMap());

    // İstatistikleri güncelle - başarı sayısını ve puanı ekle
    final updatedStats = stats.copyWith(
      totalAchievements: stats.totalAchievements + 1,
      totalPoints: stats.totalPoints + achievement.points,
      unlockedAchievements: [...stats.unlockedAchievements, achievement.id],
    );

    await _userStatsCollection.doc(userId).set(updatedStats.toMap());
  }

  /// Başarı ilerlemesini güncelle
  Future<void> _updateAchievementProgress(
    String userId,
    String achievementId,
    int progress,
  ) async {
    await _userAchievementsCollection
        .doc(userId)
        .collection('achievements')
        .doc(achievementId)
        .set({
      'achievementId': achievementId,
      'progress': progress,
      'isUnlocked': false,
      'unlockedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// Liderboard (Sıralama) getir
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 100}) async {
    try {
      final snapshot = await _userStatsCollection
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();

      final entries = <LeaderboardEntry>[];
      int rank = 1;

      for (final doc in snapshot.docs) {
        final stats = UserStats.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        
        // Kullanıcı bilgilerini getir
        final userDoc = await _firestore.collection('students').doc(stats.userId).get();
        final userName = userDoc.data()?['fullName'] ?? 'Anonim';
        final photoUrl = userDoc.data()?['photoUrl'];

        entries.add(LeaderboardEntry(
          userId: stats.userId,
          userName: userName,
          photoUrl: photoUrl,
          totalPoints: stats.totalPoints,
          level: stats.level,
          rank: rank,
          rankTitle: stats.rankTitle,
          achievementCount: stats.totalAchievements,
        ));

        rank++;
      }

      return entries;
    } catch (e) {
      print('Liderboard yüklenirken hata: $e');
      return [];
    }
  }

  /// Kullanıcının sıralamasını getir
  Future<int> getUserRank(String userId) async {
    try {
      final userStats = await getUserStats(userId);
      if (userStats == null) return 0;

      final snapshot = await _userStatsCollection
          .where('totalPoints', isGreaterThan: userStats.totalPoints)
          .get();

      return snapshot.docs.length + 1;
    } catch (e) {
      print('Kullanıcı sıralaması hesaplanırken hata: $e');
      return 0;
    }
  }

  /// Varsayılan başarıları oluştur (ilk kurulum için)
  Future<void> initializeDefaultAchievements() async {
    final achievements = _getDefaultAchievements();
    
    for (final achievement in achievements) {
      await _achievementsCollection.doc(achievement.id).set(achievement.toMap());
    }
  }

  /// Varsayılan başarı listesi
  List<Achievement> _getDefaultAchievements() {
    return [
      // Materyal Yükleme Başarıları
      Achievement(
        id: 'material_1',
        title: 'İlk Adım',
        description: 'İlk materyalini yükle',
        category: AchievementCategory.materialUpload,
        tier: AchievementTier.bronze,
        points: 50,
        iconName: 'upload',
        requiredValue: 1,
      ),
      Achievement(
        id: 'material_10',
        title: 'Koleksiyoncu',
        description: '10 materyal yükle',
        category: AchievementCategory.materialUpload,
        tier: AchievementTier.silver,
        points: 150,
        iconName: 'folder',
        requiredValue: 10,
      ),
      Achievement(
        id: 'material_50',
        title: 'Kütüphane',
        description: '50 materyal yükle',
        category: AchievementCategory.materialUpload,
        tier: AchievementTier.gold,
        points: 500,
        iconName: 'library_books',
        requiredValue: 50,
      ),
      Achievement(
        id: 'material_100',
        title: 'Arşivci',
        description: '100 materyal yükle',
        category: AchievementCategory.materialUpload,
        tier: AchievementTier.platinum,
        points: 1000,
        iconName: 'archive',
        requiredValue: 100,
      ),

      // Test Çözme Başarıları
      Achievement(
        id: 'test_1',
        title: 'İlk Test',
        description: 'İlk testini tamamla',
        category: AchievementCategory.testCompletion,
        tier: AchievementTier.bronze,
        points: 50,
        iconName: 'quiz',
        requiredValue: 1,
      ),
      Achievement(
        id: 'test_10',
        title: 'Çalışkan',
        description: '10 test tamamla',
        category: AchievementCategory.testCompletion,
        tier: AchievementTier.silver,
        points: 150,
        iconName: 'school',
        requiredValue: 10,
      ),
      Achievement(
        id: 'test_50',
        title: 'Sınav Ustası',
        description: '50 test tamamla',
        category: AchievementCategory.testCompletion,
        tier: AchievementTier.gold,
        points: 500,
        iconName: 'workspace_premium',
        requiredValue: 50,
      ),
      Achievement(
        id: 'test_100',
        title: 'Test Makinesi',
        description: '100 test tamamla',
        category: AchievementCategory.testCompletion,
        tier: AchievementTier.diamond,
        points: 1500,
        iconName: 'emoji_events',
        requiredValue: 100,
      ),

      // Çalışma Süresi Başarıları
      Achievement(
        id: 'time_60',
        title: 'İlk Saat',
        description: 'Toplam 60 dakika çalış',
        category: AchievementCategory.studyTime,
        tier: AchievementTier.bronze,
        points: 100,
        iconName: 'schedule',
        requiredValue: 60,
      ),
      Achievement(
        id: 'time_300',
        title: 'Azimli',
        description: 'Toplam 5 saat çalış',
        category: AchievementCategory.studyTime,
        tier: AchievementTier.silver,
        points: 250,
        iconName: 'timer',
        requiredValue: 300,
      ),
      Achievement(
        id: 'time_1200',
        title: 'Maraton',
        description: 'Toplam 20 saat çalış',
        category: AchievementCategory.studyTime,
        tier: AchievementTier.gold,
        points: 750,
        iconName: 'hourglass_full',
        requiredValue: 1200,
      ),
      Achievement(
        id: 'time_6000',
        title: 'Efsane Çalışkan',
        description: 'Toplam 100 saat çalış',
        category: AchievementCategory.studyTime,
        tier: AchievementTier.platinum,
        points: 2000,
        iconName: 'star_rate',
        requiredValue: 6000,
      ),

      // Ardışık Gün (Streak) Başarıları
      Achievement(
        id: 'streak_3',
        title: 'Alışkanlık',
        description: '3 gün üst üste çalış',
        category: AchievementCategory.streak,
        tier: AchievementTier.bronze,
        points: 100,
        iconName: 'local_fire_department',
        requiredValue: 3,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Hafta Şampiyonu',
        description: '7 gün üst üste çalış',
        category: AchievementCategory.streak,
        tier: AchievementTier.silver,
        points: 300,
        iconName: 'whatshot',
        requiredValue: 7,
      ),
      Achievement(
        id: 'streak_30',
        title: 'Ay Yıldızı',
        description: '30 gün üst üste çalış',
        category: AchievementCategory.streak,
        tier: AchievementTier.gold,
        points: 1000,
        iconName: 'stars',
        requiredValue: 30,
      ),
      Achievement(
        id: 'streak_100',
        title: 'Durmak Yok',
        description: '100 gün üst üste çalış',
        category: AchievementCategory.streak,
        tier: AchievementTier.diamond,
        points: 5000,
        iconName: 'military_tech',
        requiredValue: 100,
      ),

      // Tam Puan Başarıları
      Achievement(
        id: 'perfect_1',
        title: 'İlk Mükemmellik',
        description: 'İlk tam puanını al',
        category: AchievementCategory.perfectScore,
        tier: AchievementTier.bronze,
        points: 100,
        iconName: 'grade',
        requiredValue: 1,
      ),
      Achievement(
        id: 'perfect_10',
        title: 'Mükemmelliyetçi',
        description: '10 tam puan al',
        category: AchievementCategory.perfectScore,
        tier: AchievementTier.gold,
        points: 500,
        iconName: 'verified',
        requiredValue: 10,
      ),
      Achievement(
        id: 'perfect_50',
        title: 'Hatasız',
        description: '50 tam puan al',
        category: AchievementCategory.perfectScore,
        tier: AchievementTier.platinum,
        points: 2000,
        iconName: 'diamond',
        requiredValue: 50,
      ),

      // Seviye Başarıları
      Achievement(
        id: 'level_10',
        title: 'Yükseliş',
        description: 'Seviye 10\'a ulaş',
        category: AchievementCategory.improvement,
        tier: AchievementTier.silver,
        points: 200,
        iconName: 'trending_up',
        requiredValue: 10,
      ),
      Achievement(
        id: 'level_25',
        title: 'Uzman Yolunda',
        description: 'Seviye 25\'e ulaş',
        category: AchievementCategory.improvement,
        tier: AchievementTier.gold,
        points: 500,
        iconName: 'arrow_circle_up',
        requiredValue: 25,
      ),
      Achievement(
        id: 'level_50',
        title: 'Usta',
        description: 'Seviye 50\'ye ulaş',
        category: AchievementCategory.improvement,
        tier: AchievementTier.platinum,
        points: 1500,
        iconName: 'auto_awesome',
        requiredValue: 50,
      ),
      Achievement(
        id: 'level_100',
        title: 'Efsane',
        description: 'Seviye 100\'e ulaş',
        category: AchievementCategory.improvement,
        tier: AchievementTier.diamond,
        points: 5000,
        iconName: 'emoji_events',
        requiredValue: 100,
      ),
    ];
  }
}
