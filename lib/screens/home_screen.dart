import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/models/book.dart';
import 'package:inkwave/services/books_api.dart';
import 'package:inkwave/widgets/newest_books_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, List<Book>> booksByInterest = {};  // Her bir ilgi alanı için kitaplar
  bool _isLoading = true;
  bool _hasError = false;
  List<String> _interestKeywords = [];

  @override
  void initState() {
    super.initState();
    _loadUserInterestAndBooks();
  }

  Future<void> _loadUserInterestAndBooks() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null && doc.data()!.containsKey("interest")) {
          final interestData = doc["interest"];
          if (interestData is List && interestData.isNotEmpty) {
            _interestKeywords = List<String>.from(interestData);
          }
        }
      }
    } catch (e) {
      debugPrint("İlgi alanı alınamadı: $e");
    } finally {
      await _fetchBooks();
    }
  }

  Future<void> _fetchBooks() async {
    try {
      Map<String, List<Book>> allBooks = {};

      for (String interestKeyword in _interestKeywords) {
        final fetchedBooks = await BooksApi.searchBooks(interestKeyword);
        allBooks[interestKeyword] = fetchedBooks;  // Her ilgi alanı için kitaplar
      }

      setState(() {
        booksByInterest = allBooks;  // Map'i güncelliyoruz
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPage() async {
    await _loadUserInterestAndBooks();
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
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        color: Colors.white,
        backgroundColor: AppConstants.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_hasError)
                const Center(
                  child: Text("Kitaplar yüklenirken hata oluştu!",
                      style: TextStyle(color: Colors.white)),
                )
              else
                NewestBooksWidget(books: booksByInterest.values.expand((x) => x).toList()),

              const SizedBox(height: 30),
              // Her ilgi alanını ayrı bir başlık olarak göstermek
              if (_interestKeywords.isNotEmpty)
                for (var keyword in _interestKeywords)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$keyword ile ilgili kitaplar", style: AppConstants.headlineStyle),
                      const SizedBox(height: 10),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_hasError)
                        const Center(
                          child: Text("Kitaplar yüklenirken hata oluştu!",
                              style: TextStyle(color: Colors.white)),
                        )
                      else
                      // Yatay kitaplar için ListView.builder'ı yatay yapıyoruz
                        SizedBox(
                          height: 230,  // Yatay liste için yüksekliği biraz daha artırdık
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,  // Yatay kaydırma
                            itemCount: booksByInterest[keyword]?.length ?? 0,
                            itemBuilder: (context, index) {
                              final book = booksByInterest[keyword]![index];
                              return Card(
                                color: Colors.white10,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: SizedBox(
                                  width: 140,  // Her bir kitap için genişlik
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: SizedBox(
                                          width: 130,
                                          height: 170,
                                          child: book.imageUrl.isNotEmpty
                                              ? Image.network(book.imageUrl, fit: BoxFit.cover)
                                              : const Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Başlık metnini kısaltma ve iki satıra sığdırma
                                      Text(
                                        book.title,
                                        style: const TextStyle(color: Colors.white),
                                        maxLines: 1,  // Başlık iki satıra kadar olacak
                                        overflow: TextOverflow.ellipsis,  // Taşma durumunda '...' ekleyelim
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '⭐ ${book.rating.toStringAsFixed(1)}',
                                        style: AppConstants.subtitleStyle,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
