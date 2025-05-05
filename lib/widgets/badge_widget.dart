import 'package:flutter/material.dart';
import '../models/badge_model.dart' as custom;

class BadgeWidget extends StatelessWidget {
  final custom.Badge badge;

  const BadgeWidget({Key? key, required this.badge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Text(
        badge.emoji,
        style: const TextStyle(fontSize: 18),
      ),
      label: Text(
        badge.name,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: badge.color.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
