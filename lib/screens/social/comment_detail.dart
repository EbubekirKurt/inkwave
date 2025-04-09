import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';

class CommentDetailsPage extends StatelessWidget {
  final String profileImage;
  final String name;
  final String content;

  const CommentDetailsPage({
    super.key,
    required this.profileImage,
    required this.name,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        iconTheme: const IconThemeData(color: AppConstants.textColor),
        title: const Text('Yorum Detayı', style: AppConstants.headlineStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage(profileImage),
                ),
                const SizedBox(width: 12),
                Text(
                  name,
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
          ],
        ),
      ),
    );
  }
}
