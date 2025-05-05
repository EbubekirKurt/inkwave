import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:inkwave/constants.dart';
import 'package:inkwave/screens/profile/edit_personal_details.dart';
import 'package:inkwave/widgets/settings_drawer.dart';
import 'package:inkwave/screens/login.dart';

import 'package:inkwave/models/badge_model.dart' as custom;
import 'package:inkwave/services/badge_service.dart';
import 'package:inkwave/widgets/badge_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _bookCount = 0;
  int _score = 0;
  String _readingTime = "0 saat";
  List<custom.Badge> _badges = [];

  @override
  void initState() {
    super.initState();
    _refreshProfile(); // sayfa açıldığında tüm verileri yükle
  }

  Future<void> _refreshProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await BadgeService().assignBadgesForUser(user);
    await _loadStats();
    await _loadBadges();
  }

  Future<void> _loadStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
    final data = doc.data() ?? {};

    final bookCount = (data['total_book_count'] ?? 0) as int;
    final score = (data['leaderboard_score'] ?? 0) as int;
    final timeSpentSeconds = (data['time_spent'] ?? 0) as int;

    final hours = timeSpentSeconds ~/ 3600;
    final minutes = (timeSpentSeconds % 3600) ~/ 60;

    setState(() {
      _bookCount = bookCount;
      _score = score;
      _readingTime = "$hours saat $minutes dakika";
    });
  }

  Future<void> _loadBadges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final badgeList = await BadgeService().getUserBadges(user.uid);
    setState(() {
      _badges = badgeList;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().disconnect();
    await GoogleSignIn().signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text("Profil", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => SettingsDrawer.show(context),
            tooltip: "Ayarlar",
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.transparent,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              user?.displayName ?? "Kullanıcı Adı",
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              user?.email ?? "",
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: _buildStatCard("Okunan Kitap", "$_bookCount", Icons.book)),
                const SizedBox(width: 10),
                Expanded(child: _buildStatCard("Puan", "$_score", Icons.emoji_events)),
              ],
            ),
            const SizedBox(height: 10),
            _buildStatCard("Okuma Süresi", _readingTime, Icons.access_time),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditPersonalDetailsScreen()),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text("Kişisel Bilgileri Düzenle"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Rozetler", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            _buildBadgesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      color: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.white70)),
            ),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection() {
    if (_badges.isEmpty) {
      return const Text("Henüz rozet kazanılmadı.", style: TextStyle(color: Colors.white70));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _badges.map((badge) => BadgeWidget(badge: badge)).toList(),
    );
  }
}
