import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  void _goToSettings(BuildContext context) {
    // Ayarlar sayfasına gidebilir veya popup açılabilir.
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ayarlar"),
        content: const Text("Burada ayarlar görünebilir."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppConstants.primaryColor,
        appBar: AppBar(
          backgroundColor: AppConstants.primaryColor,
          title: const Text("Profilim"),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _goToSettings(context),
            ),
          ],
        ),
        body: Center(
          child: Text(
            "Kullanıcı Bilgileri\n\nBurada kullanıcı profil bilgileri yer alacak.",
            textAlign: TextAlign.center,
            style: AppConstants.subtitleStyle,
          ),
        ),
      ),
    );
  }
}
