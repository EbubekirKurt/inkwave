import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/screens/social/comment_detail.dart';
import 'package:inkwave/screens/social/add_comment.dart'; // Import the AddCommentPage

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  _SocialPageState createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text('Düşüncelerini bizimle paylaş!', style: AppConstants.headlineStyle),
        iconTheme: const IconThemeData(color: AppConstants.textColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('social')
            .orderBy('created_at', descending: true) // Sorting by date
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz hiçbir yorum bulunmuyor."));
          }

          final comments = snapshot.data!.docs;

          return RefreshIndicator(
            onRefresh: _refreshComments,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.padding),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final commentData = comments[index];
                final String commentId = commentData.id; // Retrieve commentId
                final String profileImage = 'assets/profile_placeholder.png'; // Placeholder for profile image
                final List<dynamic> userDetails = commentData['user_details'] ?? [];
                final String name = userDetails.isNotEmpty
                    ? '${userDetails[0]['name']} ${userDetails[0]['surname']}'
                    : 'Unknown User';
                final String content = commentData['text'] ?? 'No content available';
                final Timestamp createdAt = commentData['created_at'] as Timestamp;
                final DateTime dateTime = createdAt.toDate();
                final int likeCount = commentData['like_count'] ?? 0;
                final int commentCount = commentData['comment_count'] ?? 0;
                final List<dynamic> likes = commentData['likes'] ?? [];

                return _buildSocialPost(
                  context: context,
                  profileImage: profileImage,
                  name: name,
                  content: content,
                  createdAt: dateTime,
                  commentId: commentId, // Pass the commentId here
                  likeCount: likeCount,
                  commentCount: commentCount,
                  likes: likes,
                );
              },
            ),
          );
        },
      ),
      // Floating Action Button (FAB) to add a comment
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCommentPage()),
          );
        },
        backgroundColor: AppConstants.accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _refreshComments() async {
    setState(() {});
  }

  Widget _buildSocialPost({
    required BuildContext context,
    required String profileImage,
    required String name,
    required String content,
    required DateTime createdAt,
    required String commentId,
    required int likeCount,
    required int commentCount,
    required List<dynamic> likes,
  }) {
    User? user = FirebaseAuth.instance.currentUser;
    bool hasLiked = likes.contains(user?.uid);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommentDetailsPage(
              profileImage: profileImage,
              name: name,
              content: content,
              commentId: commentId, // Pass the commentId to CommentDetailsPage
            ),
          ),
        );
      },
      child: Card(
        color: AppConstants.accentColor,
        elevation: 4,
        margin: const EdgeInsets.only(bottom: AppConstants.padding),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage(profileImage),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppConstants.headlineStyle.copyWith(fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: AppConstants.subtitleStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yorum Tarihi: ${createdAt.toLocal()}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            hasLiked ? Icons.thumb_up : Icons.thumb_up_off_alt,
                            color: hasLiked ? Colors.blue : Colors.grey,
                          ),
                          onPressed: () {
                            _toggleLike(commentId, likes);
                          },
                        ),
                        Text('$likeCount Likes'),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.comment, color: Colors.grey),
                          onPressed: () {
                            // Handle navigating to the comment section
                          },
                        ),
                        Text('$commentCount Comments'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLike(String commentId, List<dynamic> likes) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool hasLiked = likes.contains(user.uid);

    try {
      if (hasLiked) {
        // Unlike the comment
        await FirebaseFirestore.instance.collection('social').doc(commentId).update({
          'like_count': FieldValue.increment(-1),
          'likes': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        // Like the comment
        await FirebaseFirestore.instance.collection('social').doc(commentId).update({
          'like_count': FieldValue.increment(1),
          'likes': FieldValue.arrayUnion([user.uid]),
        });
      }
    } catch (e) {
      print("Error toggling like: $e");
    }
  }
}
