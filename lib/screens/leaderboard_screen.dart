import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/gamification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Sıralama/Yarış Ekranı
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final GamificationService _gamificationService = GamificationService();
  late String _userId;
  bool _isLoading = true;

  List<LeaderboardEntry> _leaderboard = [];
  UserStats? _myStats;
  int _myRank = 0;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser!.uid;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _leaderboard = await _gamificationService.getLeaderboard(limit: 100);
    _myStats = await _gamificationService.getUserStats(_userId);
    _myRank = await _gamificationService.getUserRank(_userId);
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sıralama'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_myStats == null) {
      return const Center(child: Text('Veri yüklenemedi'));
    }

    return Column(
      children: [
        // Benim istatistiklerim
        _buildMyStatsCard(),
        
        // Top 3 podium
        if (_leaderboard.length >= 3) _buildPodium(),
        
        // Sıralama listesi
        Expanded(
          child: _buildLeaderboardList(),
        ),
      ],
    );
  }

  Widget _buildMyStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[700]!, Colors.indigo[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Senin İstatistiğin',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMyStatItem(
                icon: Icons.emoji_events,
                label: 'Sıralama',
                value: '#$_myRank',
              ),
              Container(width: 1, height: 60, color: Colors.white30),
              _buildMyStatItem(
                icon: Icons.star,
                label: 'Puan',
                value: '${_myStats!.totalPoints}',
              ),
              Container(width: 1, height: 60, color: Colors.white30),
              _buildMyStatItem(
                icon: Icons.trending_up,
                label: 'Seviye',
                value: '${_myStats!.level}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _myStats!.rankTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
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

  Widget _buildPodium() {
    final first = _leaderboard[0];
    final second = _leaderboard.length > 1 ? _leaderboard[1] : null;
    final third = _leaderboard.length > 2 ? _leaderboard[2] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2. sıra
          if (second != null)
            _buildPodiumItem(second, 2, Colors.grey[400]!, 120),
          
          const SizedBox(width: 12),
          
          // 1. sıra
          _buildPodiumItem(first, 1, Colors.amber[400]!, 140),
          
          const SizedBox(width: 12),
          
          // 3. sıra
          if (third != null)
            _buildPodiumItem(third, 3, Colors.brown[400]!, 100),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    LeaderboardEntry entry,
    int rank,
    Color color,
    double height,
  ) {
    return Column(
      children: [
        // Profil resmi
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            image: entry.photoUrl != null
                ? DecorationImage(
                    image: NetworkImage(entry.photoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: entry.photoUrl == null
              ? Icon(Icons.person, size: 30, color: Colors.grey[600])
              : null,
        ),
        
        const SizedBox(height: 8),
        
        // İsim
        SizedBox(
          width: 80,
          child: Text(
            entry.userName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Puan
        Text(
          '${entry.totalPoints}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Podium
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList() {
    if (_leaderboard.isEmpty) {
      return const Center(
        child: Text('Henüz kimse sıralamaya girmemiş'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaderboard.length,
      itemBuilder: (context, index) {
        final entry = _leaderboard[index];
        final isMe = entry.userId == _userId;
        
        return _buildLeaderboardCard(entry, isMe);
      },
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, bool isMe) {
    Color? rankColor;
    if (entry.rank == 1) rankColor = Colors.amber[700];
    if (entry.rank == 2) rankColor = Colors.grey[600];
    if (entry.rank == 3) rankColor = Colors.brown[600];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isMe ? 4 : 1,
      color: isMe ? Colors.indigo[50] : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        
        // Sıra numarası
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: rankColor ?? Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                color: rankColor != null ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        
        // Profil resmi ve isim
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: entry.photoUrl != null
                  ? NetworkImage(entry.photoUrl!)
                  : null,
              child: entry.photoUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.userName,
                    style: TextStyle(
                      fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  Text(
                    entry.rankTitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // İstatistikler
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${entry.totalPoints}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.achievementCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
