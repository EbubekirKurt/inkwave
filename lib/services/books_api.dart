import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class BooksApi {
  static const String _baseUrl = "https://www.googleapis.com/books/v1/volumes";

  static Future<List<Book>> searchBooks(String query, {int maxResults = 40, bool saveToFirebase = false}) async {
    final uri = Uri.parse("$_baseUrl?q=$query&maxResults=${maxResults.clamp(1, 10)}");
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Kitaplar yüklenemedi: ${response.statusCode}");
    }

    final data = json.decode(response.body);
    final List items = data['items'] ?? [];
    final List<Book> books = items.map((item) => Book.fromJson(item)).toList();

    if (saveToFirebase) {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final book in books) {
        if (book.id.isEmpty) continue;
        final docRef = firestore.collection('books').doc(book.id);

        final docSnap = await docRef.get();
        if (!docSnap.exists) {
          batch.set(docRef, book.toMap());
        }
      }

      // Tümünü tek seferde yaz
      await batch.commit();
    }

    return books;
  }
}
