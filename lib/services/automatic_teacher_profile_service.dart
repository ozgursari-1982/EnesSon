import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_style_profile.dart';
import '../models/document_analysis.dart';
import 'teacher_style_analyzer.dart';
import 'firestore_service.dart';

/// PHASE 2.1: Automatic Teacher Profile System
/// This service automatically analyzes materials and builds teacher profiles
class AutomaticTeacherProfileService {
  final TeacherStyleAnalyzer _analyzer = TeacherStyleAnalyzer();
  final FirestoreService _firestore = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Called when a material is uploaded
  /// Automatically analyzes the document and updates teacher profile if needed
  Future<void> onMaterialUploaded({
    required String materialId,
    required String courseId,
    required String studentId,
    required String filePath,
    required String courseName,
    required String teacherName,
    required String documentTitle,
  }) async {
    try {
      print('📄 Materyal yüklendi. Öğretmen stili analiz ediliyor...');
      
      // 1. Analyze document for teacher style
      final analysis = await _analyzer.analyzeDocumentForTeacherStyle(
        filePath: filePath,
        courseName: courseName,
        documentTitle: documentTitle,
        teacherName: teacherName,
        documentId: materialId,
      );
      
      // 2. Save analysis to Firestore
      await _db.collection('document_analyses').doc(materialId).set(analysis.toMap());
      
      print('✅ Belge analizi kaydedildi');
      
      // 3. Check and update teacher profile
      await _checkAndUpdateProfile(
        courseId: courseId,
        studentId: studentId,
        courseName: courseName,
        teacherName: teacherName,
      );
      
    } catch (e) {
      print('❌ Otomatik analiz hatası: $e');
      // Don't throw - this is a background operation
    }
  }

  /// Check if profile needs update and update if necessary
  Future<void> _checkAndUpdateProfile({
    required String courseId,
    required String studentId,
    required String courseName,
    required String teacherName,
  }) async {
    try {
      // Count analyzed documents for this course
      final analysisSnapshot = await _db
          .collection('document_analyses')
          .where('courseId', isEqualTo: courseId)
          .get();
      
      final analysisCount = analysisSnapshot.docs.length;
      
      print('📊 Analiz edilen belge sayısı: $analysisCount');
      
      if (analysisCount >= 3) {
        print('🎓 Yeterli belge var! Öğretmen profili oluşturuluyor...');
        
        // Build teacher profile
        final profile = await _analyzer.buildTeacherProfile(
          courseId: courseId,
          studentId: studentId,
          courseName: courseName,
          teacherName: teacherName,
        );
        
        if (profile != null) {
          // Save profile
          await _db.collection('teacher_profiles').doc(courseId).set(profile.toMap());
          
          print('✅ Öğretmen profili kaydedildi!');
          
          // TODO: Send notification to user
          // await _notifyUser(courseId, studentId, profile);
        }
      } else {
        print('⏳ ${3 - analysisCount} belge daha gerekli');
      }
    } catch (e) {
      print('❌ Profil güncelleme hatası: $e');
    }
  }

  /// Get profile status for a course
  Future<ProfileStatus> getProfileStatus(String courseId) async {
    try {
      // Check if profile exists
      final profileDoc = await _db
          .collection('teacher_profiles')
          .doc(courseId)
          .get();
      
      if (profileDoc.exists) {
        final profile = TeacherStyleProfile.fromMap(profileDoc.data()!);
        return ProfileStatus(
          isReady: true,
          profile: profile,
          analysisCount: profile.totalDocumentsAnalyzed,
          remainingCount: 0,
          message: '🎓 Öğretmen profili hazır!',
        );
      }
      
      // Count analyzed documents
      final analysisSnapshot = await _db
          .collection('document_analyses')
          .where('courseId', isEqualTo: courseId)
          .get();
      
      final count = analysisSnapshot.docs.length;
      
      return ProfileStatus(
        isReady: false,
        analysisCount: count,
        remainingCount: 3 - count,
        message: count == 0
            ? '🔍 Henüz materyal analiz edilmedi'
            : '⏳ ${3 - count} belge daha yükle!',
      );
    } catch (e) {
      print('❌ Profil durumu hatası: $e');
      return ProfileStatus(
        isReady: false,
        analysisCount: 0,
        remainingCount: 3,
        message: 'Durum belirlenemedi',
      );
    }
  }

  /// Force rebuild profile (for debugging/admin)
  Future<void> rebuildProfile({
    required String courseId,
    required String studentId,
    required String courseName,
    required String teacherName,
  }) async {
    print('🔄 Profil yeniden oluşturuluyor...');
    await _checkAndUpdateProfile(
      courseId: courseId,
      studentId: studentId,
      courseName: courseName,
      teacherName: teacherName,
    );
  }
}

/// Status of teacher profile for a course
class ProfileStatus {
  final bool isReady;
  final TeacherStyleProfile? profile;
  final int analysisCount;
  final int remainingCount;
  final String message;

  ProfileStatus({
    required this.isReady,
    this.profile,
    this.analysisCount = 0,
    this.remainingCount = 3,
    required this.message,
  });

  double get progress => analysisCount / 3.0;
}
