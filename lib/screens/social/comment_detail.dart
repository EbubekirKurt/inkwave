import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inkwave/constants.dart';

class CommentDetailsPage extends StatefulWidget {
  final String name;
  final String content;
  final String commentId;

  const CommentDetailsPage({
    super.key,
    required this.name,
    required this.content,
    required this.commentId, required String profileImage,
  });

  @override
  _CommentDetailsPageState createState() => _CommentDetailsPageState();
}

class _CommentDetailsPageState extends State<CommentDetailsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _replyController = TextEditingController();
  bool _isSubmitting = false;

  // Function to submit a reply
  Future<void> _submitReply() async {
    if (_replyController.text.isEmpty) {
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

      // Create the reply object
      Map<String, dynamic> reply = {
        'uid': user.uid,
        'name': name,
        'surname': surname,
        'email': email,
        'text': _replyController.text,
        'commented_at': FieldValue.serverTimestamp(), // Correct usage of timestamp
      };

      // Add the reply to the 'comments' array in the comment document
      await _firestore.collection('social').doc(widget.commentId).update({
        'comments': FieldValue.arrayUnion([reply]), // Adding reply to the comments array
        'comment_count': FieldValue.increment(1), // Increment the comment count
      });

      // Clear the reply input field
      _replyController.clear();
      Navigator.pop(context); // Optionally, navigate back after the reply is added

    } catch (e) {
      print("Error saving reply: $e");
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Function to toggle like on a comment
  Future<void> _toggleLike() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Fetch the current likes list from the comment
    DocumentSnapshot commentDoc = await _firestore.collection('social').doc(widget.commentId).get();
    List<dynamic> likes = commentDoc['likes'] ?? [];

    bool hasLiked = likes.contains(user.uid);
    try {
      if (hasLiked) {
        // Unlike the comment
        await _firestore.collection('social').doc(widget.commentId).update({
          'like_count': FieldValue.increment(-1),
          'likes': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        // Like the comment
        await _firestore.collection('social').doc(widget.commentId).update({
          'like_count': FieldValue.increment(1),
          'likes': FieldValue.arrayUnion([user.uid]),
        });
      }
    } catch (e) {
      print("Error toggling like: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        iconTheme: const IconThemeData(color: AppConstants.textColor),
        title: const Text('Yorum Detayı', style: AppConstants.headlineStyle),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('social').doc(widget.commentId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Yorum bulunamadı"));
          }

          final commentData = snapshot.data!;
          final String content = commentData['text'] ?? 'No content available';
          final Timestamp createdAt = commentData['created_at'] as Timestamp;
          final DateTime dateTime = createdAt.toDate();
          final List<dynamic> comments = commentData['comments'] ?? [];
          final List<dynamic> likes = commentData['likes'] ?? [];
          final int likeCount = commentData['like_count'] ?? 0;
          final int commentCount = commentData['comment_count'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main comment section
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/profile_placeholder.png'), // Placeholder image
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.name,
                      style: AppConstants.headlineStyle.copyWith(fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  content,
                  style: AppConstants.subtitleStyle.copyWith(
                    fontSize: 18,
                    color: AppConstants.textColor,
                  ),
                ),
                const SizedBox(height: 20),

                // Likes Section
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.thumb_up, color: Colors.blue),
                      onPressed: _toggleLike,
                    ),
                    const SizedBox(width: 8),
                    Text("Like"),
                  ],
                ),
                Row(
                  children: [
                    Text('$likeCount Likes'),
                    const SizedBox(width: 16),
                    // Displaying the users who liked
                    Wrap(
                      spacing: 5,
                      children: List.generate(likes.length, (index) {
                        String uid = likes[index];
                        return FutureBuilder<DocumentSnapshot>(
                          future: _firestore.collection('users').doc(uid).get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            if (userSnapshot.hasData && userSnapshot.data!.exists) {
                              var userData = userSnapshot.data!;
                              return CircleAvatar(
                                radius: 15,
                                backgroundImage: AssetImage('assets/profile_placeholder.png'), // Placeholder for users who liked
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Displaying comments
                Text('$commentCount Comments', style: AppConstants.headlineStyle),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 5),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage('assets/profile_placeholder.png'), // Placeholder image for each comment
                      ),
                      title: Text(comment['name'] ?? 'Unknown'),
                      subtitle: Text(comment['text'] ?? 'No content available'),
                    );
                  },
                ),

                // Reply Section
                const SizedBox(height: 20),
                TextField(
                  controller: _replyController,
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
                  onPressed: _isSubmitting ? null : _submitReply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Gönder", style: TextStyle(fontSize: 18, color: Colors.black)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
