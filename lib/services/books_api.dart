import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class BooksApi {
  static const String _baseUrl = "https://www.googleapis.com/books/v1/volumes";

  static Future<List<Book>> searchBooks(String query) async {
    final response = await http.get(Uri.parse("$_baseUrl?q=$query"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List books = data['items'];

      return books.map((book) => Book.fromJson(book)).toList();
    } else {
      throw Exception("Kitaplar yüklenemedi.");
    }
  }
}
