import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkwave/screens/login.dart';

Future<void> handleLogout(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();

    final googleSignIn = GoogleSignIn();
    final isSignedIn = await googleSignIn.isSignedIn();

    if (isSignedIn) {
      await googleSignIn.disconnect();
      await googleSignIn.signOut();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  } catch (e) {
    debugPrint("Çıkış sırasında hata oluştu: $e");
  }
}

