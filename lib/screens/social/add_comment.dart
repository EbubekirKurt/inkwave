import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inkwave/constants.dart';

class AddCommentPage extends StatefulWidget {
  const AddCommentPage({Key? key}) : super(key: key);

  @override
  _AddCommentPageState createState() => _AddCommentPageState();
}

class _AddCommentPageState extends State<AddCommentPage> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSubmitting = false;

  // Function to submit the comment
  Future<void> _submitComment() async {
    if (_commentController.text.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      // Fetch the user's data (name, surname, email) from the 'users' collection
      DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (!userSnapshot.exists) {
        print("User data not found");
        return;
      }

      var userData = userSnapshot.data() as Map<String, dynamic>;

      // Check if name, surname, and email are available
      String name = userData['name'] ?? 'Unknown';
      String surname = userData['surname'] ?? 'Unknown';
      String email = userData['email'] ?? 'No email';

      // Add the comment to Firestore with only the user details
      await _firestore.collection('social').add({
        'text': _commentController.text,
        'created_at': FieldValue.serverTimestamp(),
        'user_details': [
          {
            'uid': user.uid,
            'name': name,
            'surname': surname,
            'email': email,
          }
        ],
        'like_count': 0, // Default like count
        'comment_count': 0, // Default comment count
        'likes': [], // Empty likes array
        'comments': []
      });

      // Clear the input field
      _commentController.clear();
      // Optionally, navigate back to the previous screen after submission
      Navigator.pop(context);

    } catch (e) {
      print("Error saving comment: $e");
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text("Yorum Ekle", style: AppConstants.headlineStyle),
        iconTheme: const IconThemeData(color: AppConstants.textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Düşüncelerinizi paylaşın:',
              style: AppConstants.headlineStyle,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              style: AppConstants.subtitleStyle,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Yorumunuzu buraya yazın...',
                hintStyle: AppConstants.subtitleStyle.copyWith(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Yorum Gönder", style: TextStyle(fontSize: 18, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
