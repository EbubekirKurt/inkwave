import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/models/book.dart';
import 'package:inkwave/screens/book_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<Map<String, dynamic>>> _booksFuture;
  bool _showOnlyFavorites = false;

  @override
  void initState() {
    super.initState();
    _booksFuture = _fetchMyBooks();
  }

  Future<List<Map<String, dynamic>>> _fetchMyBooks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
    final data = snapshot.data();
    if (data == null || data['my_books'] == null) return [];

    final books = List<Map<String, dynamic>>.from(data['my_books']);

    if (_showOnlyFavorites) {
      return books.where((b) => b['is_favorite'] == true).toList();
    }

    books.sort((a, b) {
      final aFav = a['is_favorite'] == true ? 0 : 1;
      final bFav = b['is_favorite'] == true ? 0 : 1;
      return aFav.compareTo(bFav);
    });

    return books;
  }

  Future<void> _refreshBooks() async {
    final refreshed = await _fetchMyBooks();
    setState(() {
      _booksFuture = Future.value(refreshed);
    });
  }

  Future<void> _toggleFavorite(Map<String, dynamic> bookMap) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection("users").doc(user.uid);
    final snapshot = await docRef.get();
    final books = List<Map<String, dynamic>>.from(snapshot.data()?['my_books'] ?? []);

    final index = books.indexWhere(
          (b) => b['title'] == bookMap['title'] && b['author'] == bookMap['author'],
    );

    if (index != -1) {
      books[index]['is_favorite'] = !(books[index]['is_favorite'] ?? false);
      await docRef.set({'my_books': books}, SetOptions(merge: true));
      await _refreshBooks();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(books[index]['is_favorite']
            ? "Favorilere eklendi."
            : "Favorilerden çıkarıldı."),
      ));
    }
  }

  Future<void> _deleteBook(Map<String, dynamic> bookMap) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection("users").doc(user.uid);
    final snapshot = await docRef.get();
    final books = List<Map<String, dynamic>>.from(snapshot.data()?['my_books'] ?? []);

    books.removeWhere(
          (b) => b['title'] == bookMap['title'] && b['author'] == bookMap['author'],
    );

    await docRef.set({'my_books': books}, SetOptions(merge: true));
    await _refreshBooks();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Kitap silindi.")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Kitaplığım",
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),

            /// ⭐ FAVORİ TOGGLE
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.star, color: Colors.amber, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "Sadece favorileri göster",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  Switch(
                    value: _showOnlyFavorites,
                    activeColor: AppConstants.accentColor,
                    onChanged: (val) {
                      setState(() {
                        _showOnlyFavorites = val;
                        _booksFuture = _fetchMyBooks();
                      });
                    },
                  ),
                ],
              ),
            ),

            /// 📚 LİSTE
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshBooks,
                color: Colors.white,
                backgroundColor: AppConstants.primaryColor,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _booksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text("\t\t\t\t\t\t\t\t\t\t\tKitap bulunamadı. \nİnternet bağlantınızı kontrol edin.",
                            style: TextStyle(color: Colors.white70)),
                      );
                    }

                    final myBooks = snapshot.data!;

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: myBooks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final bookMap = myBooks[index];
                        final book = Book.fromMap(bookMap);

                        return Dismissible(
                          key: ValueKey("${book.title}_${book.author}"),
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 24),
                            color: Colors.amber,
                            child: const Icon(Icons.star, color: Colors.white),
                          ),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.endToStart) {
                              await _deleteBook(bookMap);
                              return true;
                            } else if (direction == DismissDirection.startToEnd) {
                              await _toggleFavorite(bookMap);
                              return false;
                            }
                            return false;
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: ListTile(
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: book.imageUrl.isNotEmpty
                                    ? Image.network(book.imageUrl,
                                    width: 50, height: 70, fit: BoxFit.cover)
                                    : const Icon(Icons.book, color: Colors.white, size: 40),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(book.title,
                                        style: const TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  if (bookMap['is_favorite'] == true)
                                    const Icon(Icons.star, color: Colors.amber, size: 20),
                                ],
                              ),
                              subtitle: Text("Yazar: ${book.author}",
                                  style: const TextStyle(color: Colors.white70)),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white38, size: 16),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BookDetailScreen(),
                                    settings: RouteSettings(arguments: book),
                                  ),
                                );
                                if (result == true) {
                                  _refreshBooks();
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
