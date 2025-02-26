import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılacak sabit değerler, renkler, boyutlar, vs.
class AppConstants {
  // Renk paleti
  static const Color primaryColor = Color(0xFF090617);
  static const Color accentColor = Color(0xFFFFC107);
  static const Color textColor = Colors.white;

  // Metin stilleri
  static const TextStyle headlineStyle = TextStyle(
    color: textColor,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: Colors.grey,
    fontSize: 16,
  );

  // Boşluk değerleri
  static const double padding = 16.0;
}
