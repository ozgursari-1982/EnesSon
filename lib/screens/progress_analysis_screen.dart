import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/course.dart';
import '../models/test.dart';
import '../services/firestore_service.dart';
import '../services/gemini_ai_service.dart';
import '../widgets/user_stats_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressAnalysisScreen extends StatefulWidget {
  const ProgressAnalysisScreen({super.key});

  @override
  State<ProgressAnalysisScreen> createState() => _ProgressAnalysisScreenState();
}

class _ProgressAnalysisScreenState extends State<ProgressAnalysisScreen> {
  final _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<Course> _courses = [];
  Map<String, List<Test>> _courseTests = {};
  Map<String, double> _courseAverages = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Dersleri yükle
      _courses = await _firestoreService.getCourses(userId);

      // Her ders için testleri yükle
      for (var course in _courses) {
        final tests = await _firestoreService.getTests(userId, course.id);
        final completedTests = tests.where((t) => t.isCompleted).toList();
        _courseTests[course.id] = completedTests;

        // Ortalama hesapla
        if (completedTests.isNotEmpty) {
          final avg = completedTests
                  .map((t) => t.score ?? 0)
                  .reduce((a, b) => a + b) /
              completedTests.length;
          _courseAverages[course.id] = avg;
        } else {
          _courseAverages[course.id] = 0;
        }
      }
    } catch (e) {
      print('Veri yükleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  DateTime _getClosestExamDate() {
    DateTime? closest;
    for (var course in _courses) {
      if (course.nextExamDate != null) {
        if (closest == null || course.nextExamDate!.isBefore(closest)) {
          closest = course.nextExamDate;
        }
      }
    }
    return closest ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analiz & İlerleme')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalTests = _courseTests.values.expand((x) => x).length;
    final overallAverage = _courseAverages.isEmpty
        ? 0.0
        : _courseAverages.values.reduce((a, b) => a + b) /
            _courseAverages.length;

    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Analiz & İlerleme'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Stats Widget (Gamification)
              if (currentUser != null)
                UserStatsWidget(userId: currentUser.uid),
              const SizedBox(height: 20),

              // Genel Durum Kartı
              _buildOverviewCard(overallAverage, totalTests),
              const SizedBox(height: 20),

              // Sınav Geri Sayım
              _buildExamCountdown(),
              const SizedBox(height: 20),

              // Ders Bazında Performans Grafiği
              if (_courses.isNotEmpty) ...[
                _buildSectionTitle('Ders Bazında Performans'),
                const SizedBox(height: 12),
                _buildPerformanceChart(),
                const SizedBox(height: 20),
              ],

              // Güçlü/Zayıf Yönler
              _buildSectionTitle('Güçlü & Zayıf Yönleriniz'),
              const SizedBox(height: 12),
              _buildStrengthsWeaknesses(),
              const SizedBox(height: 20),

              // Detaylı Ders Listesi
              _buildSectionTitle('Ders Detayları'),
              const SizedBox(height: 12),
              ..._courses.map((course) => _buildCourseDetailCard(course)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(double average, int totalTests) {
    MaterialColor cardColor;
    IconData icon;
    String status;

    if (average >= 80) {
      cardColor = Colors.green;
      icon = Icons.emoji_events;
      status = 'Mükemmel';
    } else if (average >= 60) {
      cardColor = Colors.blue;
      icon = Icons.thumb_up;
      status = 'İyi';
    } else if (average >= 40) {
      cardColor = Colors.orange;
      icon = Icons.trending_up;
      status = 'Orta';
    } else {
      cardColor = Colors.red;
      icon = Icons.warning;
      status = 'Geliştirilmeli';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor.shade400, cardColor.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            '${average.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Genel Ortalama - $status',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Dersler', '${_courses.length}', Icons.book),
              _buildStatItem('Testler', '$totalTests', Icons.quiz),
              _buildStatItem(
                'Materyaller',
                '${_courses.fold(0, (sum, c) => sum + c.uploadedFilesCount)}',
                Icons.folder,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildExamCountdown() {
    final closestExam = _getClosestExamDate();
    final daysLeft = closestExam.difference(DateTime.now()).inDays;
    
    MaterialColor color;
    String message;
    
    if (daysLeft <= 7) {
      color = Colors.red;
      message = 'YOĞUN ÇALIŞMA ZAMANI!';
    } else if (daysLeft <= 14) {
      color = Colors.orange;
      message = 'Hızlanma zamanı!';
    } else {
      color = Colors.blue;
      message = 'Düzenli çalışmaya devam!';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.shade100, color.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sınava $daysLeft Gün Kaldı',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: color.shade600,
                      fontWeight: FontWeight.w500,
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

  Widget _buildPerformanceChart() {
    if (_courses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Henüz ders eklenmemiş.'),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= _courses.length) return const Text('');
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _courses[value.toInt()].name,
                              style: const TextStyle(fontSize: 10),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(_courses.length, (index) {
                    final average = _courseAverages[_courses[index].id] ?? 0;
                    Color barColor;
                    if (average >= 70) {
                      barColor = Colors.green;
                    } else if (average >= 50) {
                      barColor = Colors.orange;
                    } else {
                      barColor = Colors.red;
                    }

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: average,
                          color: barColor,
                          width: 30,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthsWeaknesses() {
    final strengths = <Course>[];
    final weaknesses = <Course>[];

    for (var course in _courses) {
      final avg = _courseAverages[course.id] ?? 0;
      if (avg >= 70) {
        strengths.add(course);
      } else if (avg > 0) {
        weaknesses.add(course);
      }
    }

    return Column(
      children: [
        if (strengths.isNotEmpty)
          Card(
            color: Colors.green.shade50,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Güçlü Olduğunuz Dersler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...strengths.map((course) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(course.name)),
                            Text(
                              '${_courseAverages[course.id]?.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        if (strengths.isNotEmpty && weaknesses.isNotEmpty) const SizedBox(height: 12),
        if (weaknesses.isNotEmpty)
          Card(
            color: Colors.orange.shade50,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_down, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Geliştirilmesi Gereken Dersler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...weaknesses.map((course) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(course.name)),
                            Text(
                              '${_courseAverages[course.id]?.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        if (strengths.isEmpty && weaknesses.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('Henüz test çözülmemiş. Test çözerek analizinizi görebilirsiniz.'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCourseDetailCard(Course course) {
    final tests = _courseTests[course.id] ?? [];
    final average = _courseAverages[course.id] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: average >= 70
              ? Colors.green
              : average >= 50
                  ? Colors.orange
                  : Colors.red,
          child: Text(
            course.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          course.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${tests.length} test • Ortalama: ${average.toStringAsFixed(0)}%',
        ),
        children: [
          if (tests.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Henüz test çözülmemiş.'),
            )
          else
            ...tests.map((test) => ListTile(
                  dense: true,
                  leading: Icon(
                    test.score! >= 70 ? Icons.check_circle : Icons.cancel,
                    color: test.score! >= 70 ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  title: Text(test.title),
                  trailing: Text(
                    '${test.score?.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: test.score! >= 70 ? Colors.green : Colors.red,
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

