import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/screens/social/comment_detail.dart';

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text('Sosyal Medya', style: AppConstants.headlineStyle),
        iconTheme: const IconThemeData(color: AppConstants.textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.padding),
        children: [
          _buildSocialPost(
            context: context,
            profileImage: 'assets/profile_placeholder.png',
            name: 'Mehmet Ali Yılmaz',
            content:
            'Bu kitap gerçekten çok etkileyici, herkesin okumasını tavsiye ederim! 📚✨',
          ),
        ],
      ),
    );
  }

  Widget _buildSocialPost({
    required BuildContext context,
    required String profileImage,
    required String name,
    required String content,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommentDetailsPage(
              profileImage: profileImage,
              name: name,
              content: content,
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
                      style: AppConstants.headlineStyle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: AppConstants.subtitleStyle,
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
}
