import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/models/book.dart';
import 'package:inkwave/services/books_api.dart';
import 'package:inkwave/screens/book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Book> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// **📌 Kullanıcı her karakter yazdığında arama yapılacak (Debounce ile gecikmeli)**
  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchBooks();
    });
  }

  /// **📌 Kitap Arama Fonksiyonu**
  void _searchBooks() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final books = await BooksApi.searchBooks(_searchController.text);
      setState(() {
        _searchResults = books;
      });
    } catch (e) {
      print("Hata: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// **📌 Arama Kutusunu Temizleme**
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppConstants.primaryColor,
        body: Padding(
          padding: const EdgeInsets.all(AppConstants.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Kitap Ara", style: AppConstants.headlineStyle),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Kitap veya yazar ara...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: _clearSearch, // **Arama temizleme fonksiyonu**
                    )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // **Arama Sonuçları**
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                    ? const Center(
                  child: Text("Arama sonuçları burada listelenecek...",
                      style: TextStyle(color: Colors.white54)),
                )
                    : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final book = _searchResults[index];
                    return ListTile(
                      leading: book.imageUrl.isNotEmpty
                          ? Image.network(book.imageUrl, width: 50, height: 75, fit: BoxFit.cover)
                          : const Icon(Icons.book, size: 50, color: Colors.grey),
                      title: Text(book.title, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(book.author, style: const TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.arrow_forward, color: Colors.white),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BookDetailScreen(),
                            settings: RouteSettings(arguments: book),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
