import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslateApi {
  static const String _baseUrl = "https://api.mymemory.translated.net";

  static Future<List<Map<String, String>>> getLanguages() async {
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

  static Future<String> translateText(String text, String from, String to) async {
    if (text.isEmpty) return "";

    Map<String, String> langMapping = {
      "en": "en-GB",
      "tr": "tr-TR",
      "fr": "fr-FR",
      "es": "es-ES",
      "de": "de-DE",
      "it": "it-IT",
      "ru": "ru-RU",
    };

    String sourceLang = langMapping[from] ?? from;
    String targetLang = langMapping[to] ?? to;

    final Uri url = Uri.parse("$_baseUrl/get?q=${Uri.encodeComponent(text)}&langpair=$sourceLang|$targetLang");

    try {
      final response = await http.get(url);
      print("🔹 API'ye Gönderilen URL: $url");
      print("🔹 API Yanıtı: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String bestTranslation = data["responseData"]["translatedText"] ?? "Çeviri başarısız!";

        if (data.containsKey("matches") && data["matches"] is List) {
          for (var match in data["matches"]) {
            if (match["match"] != null && match["match"] >= 0.85) {
              bestTranslation = match["translation"];
              break;
            }
          }
        }

        return bestTranslation;
      } else {
        print("❌ API Hatası: ${response.statusCode}");
        return "Çeviri başarısız: API hatası.";
      }
    } catch (e) {
      print("❌ API isteği sırasında hata oluştu: $e");
      return "Çeviri başarısız!";
    }
  }
}
