# 🏆 Gamification (Oyunlaştırma) Sistemi - Kullanım Kılavuzu

## 📋 İçindekiler
1. [Genel Bakış](#genel-bakış)
2. [Özellikler](#özellikler)
3. [Kurulum](#kurulum)
4. [Kullanım](#kullanım)
5. [API Referansı](#api-referansı)
6. [UI Komponantları](#ui-komponantları)
7. [Veri Yapısı](#veri-yapısı)
8. [Sorun Giderme](#sorun-giderme)

---

## 🎯 Genel Bakış

AI Öğretmen uygulamasına eksiksiz bir oyunlaştırma sistemi eklendi. Sistem, öğrencilerin motivasyonunu artırmak ve öğrenmeyi eğlenceli hale getirmek için tasarlandı.

**Ana Bileşenler:**
- **Başarı/Madalya Sistemi:** 24 farklı başarı
- **Puan Sistemi:** Aktivitelere göre puan kazanma
- **Seviye Sistemi:** Otomatik seviye atlama
- **Rütbe Sistemi:** 9 farklı rütbe
- **Streak Sistemi:** Ardışık gün takibi
- **Liderboard:** Gerçek zamanlı sıralama

**Veri Güvenliği:**
- %100 Firebase Firestore
- Telefon değişse bile kayıp yok
- Real-time senkronizasyon

---

## ✨ Özellikler

### 1. Başarı/Madalya Sistemi

**24 Farklı Başarı (6 Kategori):**

#### Materyal Yükleme (4 başarı)
- İlk Adım (1 materyal) - Bronz - 50 puan
- Koleksiyoncu (10 materyal) - Gümüş - 150 puan
- Kütüphane (50 materyal) - Altın - 500 puan
- Arşivci (100 materyal) - Platin - 1000 puan

#### Test Çözme (4 başarı)
- İlk Test (1 test) - Bronz - 50 puan
- Çalışkan (10 test) - Gümüş - 150 puan
- Sınav Ustası (50 test) - Altın - 500 puan
- Test Makinesi (100 test) - Elmas - 1500 puan

#### Çalışma Süresi (4 başarı)
- İlk Saat (60 dakika) - Bronz - 100 puan
- Azimli (300 dakika/5 saat) - Gümüş - 250 puan
- Maraton (1200 dakika/20 saat) - Altın - 750 puan
- Efsane Çalışkan (6000 dakika/100 saat) - Platin - 2000 puan

#### Ardışık Günler (4 başarı)
- Alışkanlık (3 gün) - Bronz - 100 puan
- Hafta Şampiyonu (7 gün) - Gümüş - 300 puan
- Ay Yıldızı (30 gün) - Altın - 1000 puan
- Durmak Yok (100 gün) - Elmas - 5000 puan

#### Tam Puanlar (3 başarı)
- İlk Mükemmellik (1 tam puan) - Bronz - 100 puan
- Mükemmelliyetçi (10 tam puan) - Altın - 500 puan
- Hatasız (50 tam puan) - Platin - 2000 puan

#### Seviye Gelişimi (4 başarı)
- Yükseliş (Seviye 10) - Gümüş - 200 puan
- Uzman Yolunda (Seviye 25) - Altın - 500 puan
- Usta (Seviye 50) - Platin - 1500 puan
- Efsane (Seviye 100) - Elmas - 5000 puan

### 2. Puan Sistemi

**Materyal Yükleme:**
- İlk 10 materyal: 10 puan
- 11-50 materyal: 15 puan
- 50+ materyal: 20 puan

**Test Tamamlama:**
- %0-50 başarı: 5 puan
- %51-75 başarı: 10 puan
- %76-90 başarı: 15 puan
- %91-99 başarı: 20 puan
- %100 başarı: 30 puan

**Çalışma Süresi:**
- Her 10 dakika: 1 puan

**Başarı Kazanma:**
- Bronz: 50-100 puan
- Gümüş: 150-300 puan
- Altın: 500-1000 puan
- Platin: 1000-2000 puan
- Elmas: 1500-5000 puan

### 3. Seviye Sistemi

**Nasıl Çalışır:**
- Her seviye bir öncekinden %20 daha fazla puan gerektirir
- Seviye 1: 100 puan gerekir
- Seviye 2: 120 puan gerekir
- Seviye 3: 144 puan gerekir
- ...
- Seviye 100: ~82,817 puan gerekir

**Toplam Puan Hesabı:**
- Aktivite puanları + Başarı puanları = Toplam puan
- Toplam puan seviye ilerlemesini belirler

### 4. Rütbe Sistemi

**9 Rütbe (Seviyeye Göre):**
1. Yeni Başlayan (Seviye 1-4)
2. Çömez (Seviye 5-9)
3. Öğrenci (Seviye 10-19)
4. Çalışkan (Seviye 20-29)
5. Başarılı (Seviye 30-39)
6. Uzman (Seviye 40-49)
7. Usta (Seviye 50-74)
8. Dehâ (Seviye 75-99)
9. Efsane (Seviye 100+)

### 5. Streak (Ardışık Gün) Sistemi

**Kurallar:**
- Her gün en az 1 aktivite yapmalısın (materyal yükle, test çöz, vb.)
- Ardışık günler streak'i artırır
- 1 gün atlarsan streak sıfırlanır
- En uzun streak kaydedilir

**Streak Başarıları:**
- 3, 7, 30, 100 gün için özel başarılar

### 6. Liderboard (Sıralama)

**Özellikler:**
- Toplam puana göre sıralama
- Real-time güncelleme
- Top 3 podium gösterimi
- Kendi sıran her zaman görünür
- Profil resmi, isim, seviye, başarı sayısı

---

## 🚀 Kurulum

### 1. Firestore Koleksiyonları Oluştur

Firebase Console'da aşağıdaki koleksiyonlar otomatik oluşturulacak:
- `userStats` - Kullanıcı istatistikleri
- `achievements` - Tüm başarılar
- `userAchievements` - Kullanıcı başarıları

### 2. Varsayılan Başarıları Yükle

İlk kurulumda (sadece bir kere):

```dart
import 'package:your_app/services/gamification_service.dart';

// Main.dart veya ilk login ekranında
final gamificationService = GamificationService();
await gamificationService.initializeDefaultAchievements();
```

**Not:** Bu işlem sadece bir kere yapılmalı. Başarılar zaten varsa tekrar yüklenmez.

### 3. Dashboard'a Widget Ekle

```dart
// lib/screens/dashboard_screen.dart
import '../widgets/user_stats_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gamification widget'ı ekle
            UserStatsWidget(userId: userId),
            
            // Diğer dashboard içeriği...
          ],
        ),
      ),
    );
  }
}
```

### 4. Event'lere Bağla

#### Materyal Yüklendiğinde

```dart
// lib/screens/upload_material_screen.dart
import '../services/gamification_service.dart';
import '../widgets/user_stats_widget.dart';

Future<void> uploadMaterial() async {
  // ... materyal yükleme kodu ...
  
  // Gamification güncelle
  final gamificationService = GamificationService();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  
  final unlockedAchievements = await gamificationService.onMaterialUploaded(userId);
  
  // Başarı kazanıldıysa göster
  for (final achievement in unlockedAchievements) {
    showAchievementDialog(context, achievement);
  }
}
```

#### Test Tamamlandığında

```dart
// lib/screens/take_test_screen.dart
import '../services/gamification_service.dart';
import '../widgets/user_stats_widget.dart';

Future<void> completeTest(double score, int studyTimeMinutes) async {
  // ... test tamamlama kodu ...
  
  // Gamification güncelle
  final gamificationService = GamificationService();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  
  final unlockedAchievements = await gamificationService.onTestCompleted(
    userId,
    score: score,
    studyTimeMinutes: studyTimeMinutes,
  );
  
  // Başarı kazanıldıysa göster
  for (final achievement in unlockedAchievements) {
    showAchievementDialog(context, achievement);
  }
}
```

---

## 📱 Kullanım

### Başarılar Ekranına Git

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AchievementsScreen(),
  ),
);
```

### Liderboard Ekranına Git

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const LeaderboardScreen(),
  ),
);
```

### Kullanıcı İstatistiklerini Getir

```dart
final gamificationService = GamificationService();
final userId = FirebaseAuth.instance.currentUser!.uid;

// Bir kere getir
final stats = await gamificationService.getUserStats(userId);
print('Toplam puan: ${stats?.totalPoints}');
print('Seviye: ${stats?.level}');

// Stream ile real-time
gamificationService.getUserStatsStream(userId).listen((stats) {
  if (stats != null) {
    print('Puan güncellendi: ${stats.totalPoints}');
  }
});
```

### Sıralamayı Getir

```dart
final leaderboard = await gamificationService.getLeaderboard(limit: 100);

for (final entry in leaderboard) {
  print('#${entry.rank}: ${entry.userName} - ${entry.totalPoints} puan');
}
```

---

## 🔧 API Referansı

### GamificationService

#### onMaterialUploaded(String userId)
Materyal yüklendiğinde çağrılır. İstatistikleri günceller ve başarıları kontrol eder.

**Parametreler:**
- `userId`: Kullanıcı ID

**Dönüş:**
- `Future<List<Achievement>>`: Kazanılan başarılar listesi

**Örnek:**
```dart
final achievements = await gamificationService.onMaterialUploaded(userId);
```

#### onTestCompleted(String userId, {required double score, required int studyTimeMinutes})
Test tamamlandığında çağrılır.

**Parametreler:**
- `userId`: Kullanıcı ID
- `score`: Test puanı (0-100)
- `studyTimeMinutes`: Çalışma süresi (dakika)

**Dönüş:**
- `Future<List<Achievement>>`: Kazanılan başarılar listesi

**Örnek:**
```dart
final achievements = await gamificationService.onTestCompleted(
  userId,
  score: 85.0,
  studyTimeMinutes: 30,
);
```

#### getUserStats(String userId)
Kullanıcı istatistiklerini getirir.

**Dönüş:**
- `Future<UserStats?>`: Kullanıcı istatistikleri

#### getUserStatsStream(String userId)
Real-time kullanıcı istatistikleri.

**Dönüş:**
- `Stream<UserStats?>`: İstatistik stream'i

#### getLeaderboard({int limit = 100})
Sıralamayı getirir.

**Parametreler:**
- `limit`: Kaç kullanıcı (default: 100)

**Dönüş:**
- `Future<List<LeaderboardEntry>>`: Sıralama listesi

#### getUserRank(String userId)
Kullanıcının sırasını getirir.

**Dönüş:**
- `Future<int>`: Sıra numarası

---

## 🎨 UI Komponantları

### UserStatsWidget

Dashboard için ana widget.

**Özellikler:**
- Real-time istatistikler
- Seviye progress bar
- Streak, başarı, süre, test sayıları
- Başarılar ve Sıralama butonları

**Kullanım:**
```dart
UserStatsWidget(userId: currentUserId)
```

### AchievementsScreen

Tüm başarıları gösterir.

**Özellikler:**
- Kategorilere göre gruplu
- İlerleme çubukları
- Kazanılmış/kazanılmamış gösterimi
- Gradient renk efektleri

### LeaderboardScreen

Sıralamayı gösterir.

**Özellikler:**
- Kendi istatistiğin üstte
- Top 3 podium
- Scrollable liste
- Refresh butonu

### AchievementUnlockedDialog

Başarı kazanıldığında popup.

**Kullanım:**
```dart
showAchievementDialog(context, achievement);
```

---

## 💾 Veri Yapısı

### Firestore Koleksiyonları

#### userStats/{userId}
```json
{
  "userId": "user123",
  "totalPoints": 1250,
  "level": 12,
  "currentLevelPoints": 50,
  "nextLevelPoints": 144,
  "materialsUploaded": 25,
  "testsCompleted": 15,
  "totalStudyTimeMinutes": 480,
  "currentStreak": 7,
  "longestStreak": 15,
  "perfectScores": 3,
  "lastActivityDate": "2025-11-11T10:00:00Z",
  "unlockedAchievements": ["material_1", "test_1"],
  "totalAchievements": 2,
  "rank": 5,
  "rankTitle": "Çömez"
}
```

#### achievements/{achievementId}
```json
{
  "id": "material_1",
  "title": "İlk Adım",
  "description": "İlk materyalini yükle",
  "category": "AchievementCategory.materialUpload",
  "tier": "AchievementTier.bronze",
  "points": 50,
  "iconName": "upload",
  "requiredValue": 1,
  "isSecret": false
}
```

#### userAchievements/{userId}/achievements/{achievementId}
```json
{
  "achievementId": "material_1",
  "unlockedAt": "2025-11-10T15:30:00Z",
  "progress": 1,
  "isUnlocked": true
}
```

---

## 🐛 Sorun Giderme

### Başarılar görünmüyor

**Çözüm:**
```dart
// İlk kurulum yapıldı mı kontrol et
await GamificationService().initializeDefaultAchievements();
```

### İstatistikler güncellenmiyor

**Çözüm:**
- Firebase bağlantısını kontrol et
- `onMaterialUploaded()` veya `onTestCompleted()` çağrıldığından emin ol
- Firestore security rules'ı kontrol et

### Liderboard boş

**Çözüm:**
- En az 1 kullanıcının aktivite yapması gerekir
- Firestore index'leri oluşturulmuş mu kontrol et
- Console'da hata var mı kontrol et

### Streak sıfırlanıyor

**Çözüm:**
- Her gün en az 1 aktivite yapılmalı
- `lastActivityDate` doğru mu kontrol et
- Saat dilimi sorunları olabilir

---

## 📊 Performans İpuçları

1. **StreamBuilder kullan:** Real-time updates için
2. **Limit kullan:** Liderboard'da sadece gerekli kadar veri çek
3. **Cache kullan:** Firestore otomatik cache yapıyor
4. **Batch operations:** Çoklu güncelleme yapıyorsan batch kullan

---

## 🎓 En İyi Uygulamalar

1. **Her aktivitede güncelle:** Kullanıcı bir şey yaptığında hemen güncelle
2. **Başarıları göster:** Kazanıldığında mutlaka göster
3. **İlerleme göster:** Kullanıcı nereye geldiğini bilmeli
4. **Motivasyon:** Streak ve seviye sistemi motivasyonu artırır
5. **Sosyal:** Liderboard rekabeti teşvik eder

---

## 📝 Örnek Senaryolar

### Senaryo 1: Yeni Kullanıcı

```dart
// 1. Kullanıcı kayıt olur
// 2. İlk login
final userId = FirebaseAuth.instance.currentUser!.uid;

// 3. UserStats otomatik oluşturulur
final stats = await gamificationService.getUserStats(userId);
// stats.level = 1
// stats.totalPoints = 0

// 4. İlk materyal yükler
await gamificationService.onMaterialUploaded(userId);
// stats.totalPoints = 10 (materyal puanı)
// + "İlk Adım" başarısı kazanılır (+50 puan)
// = Toplam 60 puan

// 5. İlk test çözer (%80 başarı, 20 dakika)
await gamificationService.onTestCompleted(
  userId,
  score: 80.0,
  studyTimeMinutes: 20,
);
// + 15 puan (test)
// + 2 puan (çalışma süresi)
// + 50 puan ("İlk Test" başarısı)
// = Toplam 127 puan
// Seviye 2'ye atladı! (100 puan gerekiyordu)
```

### Senaryo 2: Streak Takibi

```dart
// Gün 1
await gamificationService.onMaterialUploaded(userId);
// currentStreak = 1

// Gün 2
await gamificationService.onTestCompleted(userId, score: 90, studyTimeMinutes: 30);
// currentStreak = 2

// Gün 3
await gamificationService.onMaterialUploaded(userId);
// currentStreak = 3
// "Alışkanlık" başarısı kazanıldı! (+100 puan)

// Gün 4 atlandı
// Gün 5
await gamificationService.onMaterialUploaded(userId);
// currentStreak = 1 (sıfırlandı)
```

### Senaryo 3: Liderboard Yarışı

```dart
// Kullanıcı A: 1000 puan
// Kullanıcı B: 950 puan
// Kullanıcı C: 900 puan

// Liderboard
final leaderboard = await gamificationService.getLeaderboard();
// #1: Kullanıcı A - 1000 puan
// #2: Kullanıcı B - 950 puan
// #3: Kullanıcı C - 900 puan

// Kullanıcı B 60 puan kazanır
await gamificationService.onTestCompleted('userB', score: 100, studyTimeMinutes: 30);
// Kullanıcı B toplam: 1010 puan

// Yeni liderboard
// #1: Kullanıcı B - 1010 puan ⬆️
// #2: Kullanıcı A - 1000 puan ⬇️
// #3: Kullanıcı C - 900 puan
```

---

## 🚀 Gelecek İyileştirmeler

Potansiyel eklemeler:
- Daily/Weekly challenges
- Özel event başarıları
- Arkadaş sistemi ve sosyal özellikler
- Rozetler ve customization
- Sezonluk yarışmalar
- Takım sistemi

---

## 📞 Destek

Sorular veya sorunlar için:
- GitHub Issues
- Repository README
- Kod içi yorumlar

---

**Son Güncelleme:** 11 Kasım 2025  
**Versiyon:** 1.0.0  
**Durum:** Üretim Hazır ✅
