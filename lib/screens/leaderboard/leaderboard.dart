import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:inkwave/constants.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        title: const Text("Liderlik Tablosu"),
        backgroundColor: AppConstants.primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppConstants.accentColor),
        titleTextStyle: AppConstants.headlineStyle,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('leaderboard_score', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppConstants.accentColor));
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Bir hata oluştu.", style: TextStyle(color: Colors.redAccent)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Henüz sıralama verisi yok.", style: TextStyle(color: Colors.white70)),
                  );
                }

                final allUsers = snapshot.data!.docs;

                final filteredUsers = allUsers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fullName = "${data['name'] ?? ''} ${data['surname'] ?? ''}".toLowerCase();
                  return fullName.contains(_searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final data = user.data() as Map<String, dynamic>;
                    final isCurrentUser = currentUser != null && user.id == currentUser.uid;

                    final rank = index + 1;
                    final score = data['leaderboard_score'] ?? 0;
                    final name = data['name'] ?? 'Kullanıcı';
                    final surname = data['surname'] ?? '';

                    String medal = '';
                    if (rank == 1) medal = ' 🥇';
                    if (rank == 2) medal = ' 🥈';
                    if (rank == 3) medal = ' 🥉';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isCurrentUser ? AppConstants.accentColor.withOpacity(0.2) : Colors.white10,
                        border: isCurrentUser
                            ? Border.all(color: AppConstants.accentColor, width: 1.5)
                            : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "$rank$medal",
                            style: TextStyle(
                              color: AppConstants.accentColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.account_circle, size: 32, color: Colors.white70),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "$name $surname",
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                          Text(
                            "$score puan",
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Kullanıcı ara...",
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          filled: true,
          fillColor: Colors.white12,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
