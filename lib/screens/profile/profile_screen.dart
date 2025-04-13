import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/screens/profile/edit_personal_details.dart';
import 'package:inkwave/widgets/settings_drawer.dart';
import 'package:inkwave/screens/login.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
            onPressed: () => SettingsDrawer.show(context, () => _handleLogout(context)),
            tooltip: "Ayarlar",
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.transparent, // tamamen arka planla uyumlu
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              user?.displayName ?? "Kullanıcı Adı",
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? "",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: _buildStatCard("Okunan Kitap", "12", Icons.book)),
                const SizedBox(width: 10),
                Expanded(child: _buildStatCard("Puan", "2450", Icons.emoji_events)),
              ],
            ),
            const SizedBox(height: 10),
            _buildStatCard("Okuma Süresi", "5 saat", Icons.access_time),

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
    final badges = [
      {"icon": Icons.local_fire_department, "label": "7 Günlük Okuma"},
      {"icon": Icons.timer, "label": "1 Saat Sürekli"},
      {"icon": Icons.auto_stories, "label": "10 Kitap"},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: badges.map((badge) {
        return Chip(
          avatar: Icon(badge["icon"] as IconData, color: Colors.white, size: 18),
          label: Text(badge["label"] as String, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurpleAccent.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      }).toList(),
    );
  }
}
