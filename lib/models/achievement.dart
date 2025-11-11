import 'package:cloud_firestore/cloud_firestore.dart';

/// Başarı/Madalya Kategorileri
enum AchievementCategory {
  materialUpload,  // Materyal yükleme
  testCompletion,  // Test çözme
  studyTime,       // Çalışma süresi
  streak,          // Ardışık günler
  perfectScore,    // Tam puan
  improvement,     // Gelişim
  social,          // Sosyal (gelecekte arkadaş sistemi için)
  special,         // Özel etkinlikler
}

/// Başarı Seviyeleri
enum AchievementTier {
  bronze,   // Bronz
  silver,   // Gümüş
  gold,     // Altın
  platinum, // Platin
  diamond,  // Elmas
}

/// Başarı/Madalya Modeli
class Achievement {
  final String id;
  final String title;          // Başlık (ör: "İlk Adım")
  final String description;    // Açıklama
  final AchievementCategory category;
  final AchievementTier tier;
  final int points;           // Kazanılan puan
  final String iconName;      // Icon adı
  final int requiredValue;    // Gereken değer (ör: 10 materyal)
  final bool isSecret;        // Gizli başarı mı?
  
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.tier,
    required this.points,
    required this.iconName,
    required this.requiredValue,
    this.isSecret = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toString(),
      'tier': tier.toString(),
      'points': points,
      'iconName': iconName,
      'requiredValue': requiredValue,
      'isSecret': isSecret,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: _parseCategory(map['category']),
      tier: _parseTier(map['tier']),
      points: map['points'] ?? 0,
      iconName: map['iconName'] ?? 'star',
      requiredValue: map['requiredValue'] ?? 0,
      isSecret: map['isSecret'] ?? false,
    );
  }

  static AchievementCategory _parseCategory(String? value) {
    return AchievementCategory.values.firstWhere(
      (e) => e.toString() == value,
      orElse: () => AchievementCategory.special,
    );
  }

  static AchievementTier _parseTier(String? value) {
    return AchievementTier.values.firstWhere(
      (e) => e.toString() == value,
      orElse: () => AchievementTier.bronze,
    );
  }
}

/// Kullanıcının Kazandığı Başarı
class UserAchievement {
  final String achievementId;
  final DateTime unlockedAt;
  final int progress;         // Mevcut ilerleme
  final bool isUnlocked;      // Kazanıldı mı?

  UserAchievement({
    required this.achievementId,
    required this.unlockedAt,
    required this.progress,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'achievementId': achievementId,
      'unlockedAt': unlockedAt.toIso8601String(),
      'progress': progress,
      'isUnlocked': isUnlocked,
    };
  }

  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      achievementId: map['achievementId'] ?? '',
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'])
          : DateTime.now(),
      progress: map['progress'] ?? 0,
      isUnlocked: map['isUnlocked'] ?? false,
    );
  }

  UserAchievement copyWith({
    int? progress,
    DateTime? unlockedAt,
    bool? isUnlocked,
  }) {
    return UserAchievement(
      achievementId: achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}

/// Kullanıcı İstatistikleri ve Ödüller
class UserStats {
  final String userId;
  final int totalPoints;              // Toplam puan
  final int level;                    // Seviye
  final int currentLevelPoints;       // Bu seviyedeki puan
  final int nextLevelPoints;          // Sonraki seviye için gereken puan
  
  // İstatistikler
  final int materialsUploaded;        // Yüklenen materyal sayısı
  final int testsCompleted;           // Tamamlanan test sayısı
  final int totalStudyTimeMinutes;    // Toplam çalışma süresi (dakika)
  final int currentStreak;            // Ardışık gün sayısı
  final int longestStreak;            // En uzun ardışık gün sayısı
  final int perfectScores;            // Tam puan sayısı
  final DateTime lastActivityDate;    // Son aktivite tarihi
  
  // Ödüller
  final List<String> unlockedAchievements; // Kazanılan başarı ID'leri
  final int totalAchievements;        // Toplam başarı sayısı
  
  // Sıralama
  final int rank;                     // Sıralama (1, 2, 3...)
  final String rankTitle;             // Rütbe (Çömez, Öğrenci, Uzman, vb.)

  UserStats({
    required this.userId,
    this.totalPoints = 0,
    this.level = 1,
    this.currentLevelPoints = 0,
    this.nextLevelPoints = 100,
    this.materialsUploaded = 0,
    this.testsCompleted = 0,
    this.totalStudyTimeMinutes = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.perfectScores = 0,
    required this.lastActivityDate,
    this.unlockedAchievements = const [],
    this.totalAchievements = 0,
    this.rank = 0,
    this.rankTitle = 'Yeni Başlayan',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'level': level,
      'currentLevelPoints': currentLevelPoints,
      'nextLevelPoints': nextLevelPoints,
      'materialsUploaded': materialsUploaded,
      'testsCompleted': testsCompleted,
      'totalStudyTimeMinutes': totalStudyTimeMinutes,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'perfectScores': perfectScores,
      'lastActivityDate': lastActivityDate.toIso8601String(),
      'unlockedAchievements': unlockedAchievements,
      'totalAchievements': totalAchievements,
      'rank': rank,
      'rankTitle': rankTitle,
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map, String userId) {
    return UserStats(
      userId: userId,
      totalPoints: map['totalPoints'] ?? 0,
      level: map['level'] ?? 1,
      currentLevelPoints: map['currentLevelPoints'] ?? 0,
      nextLevelPoints: map['nextLevelPoints'] ?? 100,
      materialsUploaded: map['materialsUploaded'] ?? 0,
      testsCompleted: map['testsCompleted'] ?? 0,
      totalStudyTimeMinutes: map['totalStudyTimeMinutes'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      perfectScores: map['perfectScores'] ?? 0,
      lastActivityDate: map['lastActivityDate'] != null
          ? DateTime.parse(map['lastActivityDate'])
          : DateTime.now(),
      unlockedAchievements: map['unlockedAchievements'] != null
          ? List<String>.from(map['unlockedAchievements'])
          : [],
      totalAchievements: map['totalAchievements'] ?? 0,
      rank: map['rank'] ?? 0,
      rankTitle: map['rankTitle'] ?? 'Yeni Başlayan',
    );
  }

  UserStats copyWith({
    int? totalPoints,
    int? level,
    int? currentLevelPoints,
    int? nextLevelPoints,
    int? materialsUploaded,
    int? testsCompleted,
    int? totalStudyTimeMinutes,
    int? currentStreak,
    int? longestStreak,
    int? perfectScores,
    DateTime? lastActivityDate,
    List<String>? unlockedAchievements,
    int? totalAchievements,
    int? rank,
    String? rankTitle,
  }) {
    return UserStats(
      userId: userId,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      currentLevelPoints: currentLevelPoints ?? this.currentLevelPoints,
      nextLevelPoints: nextLevelPoints ?? this.nextLevelPoints,
      materialsUploaded: materialsUploaded ?? this.materialsUploaded,
      testsCompleted: testsCompleted ?? this.testsCompleted,
      totalStudyTimeMinutes: totalStudyTimeMinutes ?? this.totalStudyTimeMinutes,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      perfectScores: perfectScores ?? this.perfectScores,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      totalAchievements: totalAchievements ?? this.totalAchievements,
      rank: rank ?? this.rank,
      rankTitle: rankTitle ?? this.rankTitle,
    );
  }

  /// Sonraki seviyeye yüzde ilerleme
  double get levelProgress {
    if (nextLevelPoints == 0) return 1.0;
    return currentLevelPoints / nextLevelPoints;
  }
}

/// Liderboard Girişi
class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? photoUrl;
  final int totalPoints;
  final int level;
  final int rank;
  final String rankTitle;
  final int achievementCount;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.photoUrl,
    required this.totalPoints,
    required this.level,
    required this.rank,
    required this.rankTitle,
    required this.achievementCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'photoUrl': photoUrl,
      'totalPoints': totalPoints,
      'level': level,
      'rank': rank,
      'rankTitle': rankTitle,
      'achievementCount': achievementCount,
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      photoUrl: map['photoUrl'],
      totalPoints: map['totalPoints'] ?? 0,
      level: map['level'] ?? 1,
      rank: map['rank'] ?? 0,
      rankTitle: map['rankTitle'] ?? '',
      achievementCount: map['achievementCount'] ?? 0,
    );
  }
}
