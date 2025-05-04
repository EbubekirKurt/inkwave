import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class BooksApi {
  static const String _baseUrl = "https://www.googleapis.com/books/v1/volumes";

  static Future<List<Book>> searchBooks(String query, {int maxResults = 40}) async {
    final uri = Uri.parse("$_baseUrl?q=$query&maxResults=${maxResults.clamp(1, 40)}");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List items = data['items'] ?? [];

      final List<Book> books = items.map((item) => Book.fromJson(item)).toList();

      for (final book in books) {
        if (book.id.isEmpty) continue;

        final docRef = FirebaseFirestore.instance.collection('books').doc(book.id);
        final docSnap = await docRef.get();

        if (!docSnap.exists) {
          print("📚 Kitap ekleniyor: ${book.title}");
          await docRef.set(book.toMap());
        } else {
          print("✅ Zaten var: ${book.title}");
        }
      }

      return books;
    } else {
      throw Exception("Kitaplar yüklenemedi: ${response.statusCode}");
    }
  }
}
