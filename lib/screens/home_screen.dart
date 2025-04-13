import 'package:flutter/material.dart';
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
  List<Book> books = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    try {
      final fetchedBooks = await BooksApi.searchBooks("Programming");
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
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            expandedHeight: 100.0,
            backgroundColor: AppConstants.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text("Inkwave", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
          ),

          // **Kitap İçeriklerini Gösteren Bölüm**
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // **En Yeni Kitaplar (Yatay Kaydırma)**
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_hasError)
                    const Center(
                      child: Text("Kitaplar yüklenirken hata oluştu!", style: TextStyle(color: Colors.white)),
                    )
                  else
                    NewestBooksWidget(books: books),

                  const SizedBox(height: 20),
                  const Text("Newest Books", style: AppConstants.headlineStyle),
                  const SizedBox(height: 10),

                  // **Dikey Kitap Listesi**
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
                        return ListTile(
                          leading: SizedBox(
                            width: 50,
                            height: 50,
                            child: book.imageUrl.isNotEmpty
                                ? Image.network(book.imageUrl, fit: BoxFit.cover)
                                : const Icon(Icons.broken_image, color: Colors.grey),
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
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
