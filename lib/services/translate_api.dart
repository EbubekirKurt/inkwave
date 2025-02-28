import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslateApi {
  static const String _baseUrl = "https://api.mymemory.translated.net";

  /// **📌 Desteklenen Dilleri Getir**
  static Future<List<Map<String, String>>> getLanguages() async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/get?q=Hello&langpair=en|fr"));

      if (response.statusCode == 200) {
        return [
          {"code": "en", "name": "English"},
          {"code": "tr", "name": "Türkçe"},
          {"code": "fr", "name": "Français"},
          {"code": "es", "name": "Español"},
          {"code": "de", "name": "Deutsch"},
          {"code": "it", "name": "Italiano"},
          {"code": "ru", "name": "Русский"},
        ]; // API desteklemiyor, manuel ekledik.
      } else {
        return _getDefaultLanguages(); // Hata olursa yedek diller kullanılır.
      }
    } catch (e) {
      print("Dilleri çekerken hata oluştu: $e");
      return _getDefaultLanguages(); // Hata olursa yedek diller kullanılır.
    }
  }

  /// **📌 Yedek Dil Listesi**
  static List<Map<String, String>> _getDefaultLanguages() {
    return [
      {"code": "en", "name": "English"},
      {"code": "tr", "name": "Türkçe"},
      {"code": "fr", "name": "Français"},
      {"code": "es", "name": "Español"},
      {"code": "de", "name": "Deutsch"},
      {"code": "it", "name": "Italiano"},
      {"code": "ru", "name": "Русский"},
    ];
  }

  /// **📌 Metni Çevir**
  static Future<String> translateText(String text, String from, String to) async {
    final Uri url = Uri.parse("$_baseUrl/get?q=$text&langpair=$from|$to");

    try {
      final response = await http.get(url);

      print("API Yanıtı: ${response.body}"); // 📌 Konsola yanıtı yazdır

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey("responseData") && data["responseData"]["translatedText"] != null) {
          return data["responseData"]["translatedText"];
        } else {
          return "Çeviri başarısız: Yanıtta eksik veri.";
        }
      } else {
        print("API Hata Kodu: ${response.statusCode}");
        return "Çeviri başarısız: API hatası.";
      }
    } catch (e) {
      print("API isteği sırasında hata oluştu: $e");
      return "Çeviri başarısız!";
    }
  }
}
