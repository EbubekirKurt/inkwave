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
  late Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = _fetchMyBooks();
  }

  Future<List<Book>> _fetchMyBooks() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final snapshot =
    await FirebaseFirestore.instance.collection("users").doc(currentUser.uid).get();
    final data = snapshot.data();

    if (data == null || data['my_books'] == null) return [];

    return List<Map<String, dynamic>>.from(data['my_books'])
        .map((bookMap) => Book.fromMap(bookMap))
        .toList();
  }

  Future<void> _refreshBooks() async {
    final refreshed = await _fetchMyBooks();
    setState(() {
      _booksFuture = Future.value(refreshed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppConstants.primaryColor,
        body: const Center(
          child: Text("Giriş yapmalısınız.", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "Kitaplığım",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshBooks,
                color: Colors.white,
                backgroundColor: AppConstants.primaryColor,
                child: FutureBuilder<List<Book>>(
                  future: _booksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          "Kitaplığınızda henüz kitap yok.",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      );
                    }

                    final myBooks = snapshot.data!;

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: myBooks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final book = myBooks[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BookDetailScreen(),
                                settings: RouteSettings(arguments: book),
                              ),
                            );
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
                                    ? Image.network(
                                  book.imageUrl,
                                  width: 50,
                                  height: 70,
                                  fit: BoxFit.cover,
                                )
                                    : const Icon(Icons.book, color: Colors.white, size: 40),
                              ),
                              title: Text(
                                book.title,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Yazar: ${book.author}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white38, size: 16),
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
