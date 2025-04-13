import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/models/book.dart';
import 'package:inkwave/services/books_api.dart';
import 'package:inkwave/widgets/newest_books_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> books = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _interestKeyword = "Popular"; // Default keyword

  @override
  void initState() {
    super.initState();
    _loadUserInterestAndBooks();
  }

  Future<void> _loadUserInterestAndBooks() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null && doc.data()!.containsKey("interest")) {
          final interestData = doc["interest"];
          if (interestData is List && interestData.isNotEmpty) {
            // İlk ilgi alanını kullan
            final firstInterest = interestData.first;
            if (firstInterest is String && firstInterest.isNotEmpty) {
              _interestKeyword = firstInterest;
            }
          }
        }
      }
    } catch (e) {
      print("İlgi alanı alınamadı: $e");
    } finally {
      _fetchBooks();
    }
  }

  Future<void> _fetchBooks() async {
    try {
      final fetchedBooks = await BooksApi.searchBooks(_interestKeyword);
      setState(() {
        books = fetchedBooks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        title: Stack(
          alignment: Alignment.center,
          children: [
            const Text(
              "Inkwave",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Opacity(
                  opacity: 0,
                  child: Icon(Icons.search),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/search');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_hasError)
              const Center(
                child: Text("Kitaplar yüklenirken hata oluştu!", style: TextStyle(color: Colors.white)),
              )
            else
              NewestBooksWidget(books: books),

            const SizedBox(height: 30),
            Text("$_interestKeyword Kitaplar", style: AppConstants.headlineStyle),
            const SizedBox(height: 10),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_hasError)
              const Center(
                child: Text("Kitaplar yüklenirken hata oluştu!", style: TextStyle(color: Colors.white)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return Card(
                    color: Colors.white10,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 50,
                          height: 70,
                          child: book.imageUrl.isNotEmpty
                              ? Image.network(book.imageUrl, fit: BoxFit.cover)
                              : const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                      title: Text(book.title, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        '⭐ ${book.rating.toStringAsFixed(1)}',
                        style: AppConstants.subtitleStyle,
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/bookDetail',
                          arguments: book,
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
