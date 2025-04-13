import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController feedbackController = TextEditingController();

  void _submitFeedback() {
    final text = feedbackController.text.trim();
    if (text.isNotEmpty) {
      // TODO: Firestore'a geri bildirim kaydedilebilir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geri bildiriminiz için teşekkür ederiz.")),
      );
      feedbackController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text("Geri Bildirim Gönder", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Uygulamayla ilgili görüşlerinizi bizimle paylaşabilirsiniz.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: feedbackController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Görüşleriniz...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppConstants.primaryColor,
              ),
              child: const Text("Gönder"),
            ),
          ],
        ),
      ),
    );
  }
}
