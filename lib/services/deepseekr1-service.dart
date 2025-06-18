import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class DeepSeekrService {
  static Future<List<Map<String, dynamic>>> recommendBooksFromUserData(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists || userDoc.data() == null || !userDoc.data()!.containsKey("my_books")) {
        return [];
      }

      final userBookTitles = List<String>.from(userDoc.data()!["my_books"]);
      final userVector = _buildVector(userBookTitles);

      final booksSnapshot = await FirebaseFirestore.instance.collection('books').get();
      final allBooks = booksSnapshot.docs
          .map((doc) => doc.data())
          .where((book) => book["title"] != null)
          .toList();

      final scoredBooks = <Map<String, dynamic>>[];

      for (var book in allBooks) {
        final title = book["title"] as String;
        if (userBookTitles.contains(title)) continue;

        final bookVector = _buildVector([title]);
        final score = _cosineSimilarity(userVector, bookVector);

        scoredBooks.add({...book, "score": score});
      }

      scoredBooks.sort((a, b) => (b["score"] as double).compareTo(a["score"] as double));
      return scoredBooks.take(6).toList();
    } catch (e) {
      print("DeepSeekr gerçek öneri hatası: $e");
      return [];
    }
  }

  static Map<String, double> _buildVector(List<String> titles) {
    final Map<String, int> termFreq = {};

    for (var title in titles) {
      final tokens = _tokenize(title);
      for (var token in tokens) {
        termFreq[token] = (termFreq[token] ?? 0) + 1;
      }
    }

    final total = termFreq.values.fold<int>(0, (sum, val) => sum + val);
    return termFreq.map((key, val) => MapEntry(key, val / total));
  }

  static double _cosineSimilarity(Map<String, double> v1, Map<String, double> v2) {
    final commonKeys = v1.keys.toSet().intersection(v2.keys.toSet());
    double dot = 0.0;

    for (var k in commonKeys) {
      dot += (v1[k] ?? 0) * (v2[k] ?? 0);
    }

    final norm1 = math.sqrt(v1.values.map((v) => v * v).fold(0.0, (a, b) => a + b));
    final norm2 = math.sqrt(v2.values.map((v) => v * v).fold(0.0, (a, b) => a + b));

    if (norm1 == 0 || norm2 == 0) return 0.0;
    return dot / (norm1 * norm2);
  }

  static List<String> _tokenize(String title) {
    return title.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9ğüşöçıİĞÜŞÖÇ\s]'), '').split(RegExp(r'\s+'));
  }
}
