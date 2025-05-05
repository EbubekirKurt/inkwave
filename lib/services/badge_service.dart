import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/badge_model.dart' as custom;

class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<custom.Badge>> getUserBadges(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('badges')
        .get();

    return snapshot.docs
        .map((doc) => custom.Badge.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> assignBadgesForUser(User user) async {
    final uid = user.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final badgeRef = _firestore.collection('users').doc(uid).collection('badges');
    List<custom.Badge> newBadges = [];

    void addBadge(String id, String name, String description, String emoji, Color color) {
      newBadges.add(custom.Badge(
        id: id,
        name: name,
        description: description,
        emoji: emoji,
        colorHex: color.value,
      ));
    }

    /// ✅ Onboarding & Profil
    if (data['onboarded'] == true) {
      addBadge("onboarded", "Hoş Geldin!", "İlk kez giriş yaptın", "👋", Colors.teal);
    }
    if (data['profile_completed'] == true) {
      addBadge("profile_complete", "Profil Tamamlandı", "Tüm profil bilgilerini doldurdun", "📝", Colors.blueGrey);
    }

    /// ✅ Skor Rozetleri (2000 puanlık aralıklarla)
    final int score = (data['leaderboard_score'] ?? 0) as int;
    final int scoreTier = score ~/ 2000;
    for (int i = 1; i <= scoreTier; i++) {
      addBadge("score_$i", "Puan Ustası $i", "${i * 2000} puana ulaştın", "🏆", Colors.amber.shade700);
    }

    /// ✅ Kütüphane (my_books)
    final List<dynamic> books = List.from(data['my_books'] ?? []);
    final int libraryCount = books.length;
    final List<int> bookMilestones = [5, 10, 20, 50, 100];
    for (var count in bookMilestones) {
      if (libraryCount >= count) {
        addBadge("library_$count", "$count Kitaplıkta", "$count kitabı kütüphanene ekledin", "📖", Colors.deepPurple);
      }
    }

    /// ✅ Streak (günlük okuma serisi)
    final int streak = (data['streak'] ?? 0) as int;
    final List<int> streakMilestones = [1, 15, 30, 60, 90, 120, 180, 270, 360, 720, 1080];
    for (var s in streakMilestones) {
      if (streak >= s) {
        addBadge("streak_$s", "$s Günlük Seri", "$s gün aralıksız okuma yaptın", "🔥", Colors.redAccent);
      }
    }

    /// ✅ Okuma Süresi (3600 saniye = 1 saat)
    final int seconds = (data['time_spent'] ?? 0) as int;
    final int hours = seconds ~/ 3600;
    if (hours >= 1) {
      addBadge("read_${hours}h", "$hours Saat Okuma", "$hours saat kitap okudun", "⏳", Colors.indigo);
    }

    /// ✅ Okunan Kitap Sayısı
    final int totalBooks = (data['total_book_count'] ?? 0) as int;
    final List<int> readMilestones = [1, 5, 10, 20, 50, 100, 200, 500, 750, 1000];
    for (var t in readMilestones) {
      if (totalBooks >= t) {
        addBadge("books_$t", "$t Kitap", "$t kitap bitirdin", "📚", Colors.green.shade600);
      }
    }

    /// ✅ Kayıt Süresi (created_at)
    try {
      final Timestamp created = data['created_at'] as Timestamp;
      final DateTime now = DateTime.now();
      final int months = now.difference(created.toDate()).inDays ~/ 30;
      if (months >= 1) {
        addBadge("member_$months", "$months Aylık Üye", "$months aydır bizimlesin", "📅", Colors.purple);
      }
    } catch (_) {
      // created_at yanlış formatta olabilir, hatayı yut
    }

    /// ✅ Firestore’a yükle (mevcut rozet varsa üzerine yazılır)
    for (final badge in newBadges) {
      await badgeRef.doc(badge.id).set(badge.toMap(), SetOptions(merge: true));
    }
  }
}
