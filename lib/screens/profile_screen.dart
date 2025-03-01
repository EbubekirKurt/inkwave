import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inkwave/screens/login.dart';

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

  // 🔹 Kullanıcıyı Firebase'den çıkış yaptırma fonksiyonu
  void _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); // Firebase'den çıkış yap
      await Future.delayed(const Duration(milliseconds: 500)); // Bekleme süresi, cache temizlenmesi için

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false, // Geriye dönmeyi tamamen engeller
      );
    } catch (e) {
      print("Çıkış sırasında hata oluştu: $e");
    }
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
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Center(
              child: Text(
                "Kullanıcı Bilgileri\n\nBurada kullanıcı profil bilgileri yer alacak.",
                textAlign: TextAlign.center,
                style: AppConstants.subtitleStyle,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _signOut(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Sign Out",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
