import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text("Uygulama Hakkında", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "Inkwave, okuma deneyimini geliştirmek, kelime dağarcığını artırmak ve TTS, sözlük, çeviri, not alma gibi özelliklerle "
              "kullanıcılara interaktif bir kitap okuma ortamı sunmak için tasarlanmış bir uygulamadır.",
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ),
    );
  }
}
