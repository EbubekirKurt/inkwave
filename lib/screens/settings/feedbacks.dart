// BU SAYFA SADECE ADMİNLERE AÇIK OLACAK

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:inkwave/constants.dart';

class FeedbackListScreen extends StatelessWidget {
  const FeedbackListScreen({Key? key}) : super(key: key);

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Tarih yok";
    final dateTime = timestamp.toDate();
    return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text("Gelen Geri Bildirimler", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_feedbacks')
            .orderBy('timestamp', descending: true)
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
              child: Text("Hiç geri bildirim bulunamadı.", style: TextStyle(color: Colors.white70)),
            );
          }

          final feedbacks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: feedbacks.length,
            itemBuilder: (context, index) {
              final data = feedbacks[index].data() as Map<String, dynamic>;
              final message = data['message'] ?? "Mesaj yok";
              final userId = data['userId'] ?? "Anonim";
              final timestamp = data['timestamp'] as Timestamp?;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Kullanıcı: $userId", style: const TextStyle(color: Colors.white38)),
                        Text(_formatTimestamp(timestamp), style: const TextStyle(color: Colors.white38)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
