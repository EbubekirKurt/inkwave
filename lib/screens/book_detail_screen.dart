import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/models/book.dart';
import 'package:inkwave/screens/webview_screen.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({Key? key}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? book;
  bool _isBookInLibrary = false;
  bool _isSaving = false;
  bool _isBookInLibraryChanged = false;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    // book bilgisi build içinde alınacak
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Book) {
        setState(() {
          book = args;
        });
        _checkIfBookIsInLibrary(args);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pop(context, _isBookInLibraryChanged);
        }
      },
      child: Scaffold(
        backgroundColor: AppConstants.primaryColor,
        appBar: AppBar(
          title: Text(book?.title ?? "Kitap", style: const TextStyle(color: Colors.white)),
          backgroundColor: AppConstants.primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: book == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(AppConstants.padding),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    height: 250,
                    child: book!.imageUrl.isNotEmpty
                        ? Image.network(
                      book!.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 250, color: Colors.grey),
                    )
                        : const Icon(Icons.book, size: 250, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
                Text(book!.title,
                    style: AppConstants.headlineStyle.copyWith(color: Colors.white)),
                const SizedBox(height: 8),
                Text('Yazar: ${book!.author}', style: AppConstants.subtitleStyle),
                const SizedBox(height: 8),
                Text('Puan: ${book!.rating} / 5.0',
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 20),
                _buildExpandableDescription(book!.description),
                const SizedBox(height: 30),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _toggleBookInLibrary(book!),
                    icon: Icon(_isBookInLibrary ? Icons.delete : Icons.favorite),
                    label: Text(
                      _isSaving
                          ? "İşleniyor..."
                          : (_isBookInLibrary
                          ? "Kitaplığımdan Kaldır"
                          : "Kitaplığıma Ekle"),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      _isBookInLibrary ? Colors.red : Colors.greenAccent.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                /// 📖 Kitabı Oku Butonu
                if (book!.previewLink != null && book!.previewLink!.isNotEmpty)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _openBookPreview(context, book!.previewLink!),
                      icon: const Icon(Icons.menu_book_rounded),
                      label: const Text("Kitabı Oku"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableDescription(String text) {
    const int previewMaxLength = 250;

    if (text.length <= previewMaxLength) {
      return Text(text, style: const TextStyle(color: Colors.white));
    }

    String previewText = text.substring(0, previewMaxLength) + "...";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_isDescriptionExpanded ? text : previewText,
            style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _isDescriptionExpanded = !_isDescriptionExpanded;
            });
          },
          child: Text(
            _isDescriptionExpanded ? "Daha az göster ▲" : "Devamını oku... ▼",
            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _openBookPreview(BuildContext context, String previewLink) {
    final String bookId = Uri.parse(previewLink).queryParameters['id'] ?? '';
    final String bookReaderUrl =
        "https://play.google.com/books/reader?id=$bookId&printsec=frontcover";

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WebViewScreen(url: bookReaderUrl)),
    );
  }

  Future<void> _checkIfBookIsInLibrary(Book book) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
    await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
    final data = snapshot.data();

    if (data != null && data['my_books'] != null) {
      final List books = data['my_books'];
      final exists = books.any(
              (b) => b['title'] == book.title && b['author'] == book.author);
      setState(() {
        _isBookInLibrary = exists;
      });
    }
  }

  Future<void> _toggleBookInLibrary(Book book) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    final docRef = FirebaseFirestore.instance.collection("users").doc(user.uid);

    try {
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data();
      List<dynamic> books = data?['my_books'] ?? [];

      if (_isBookInLibrary) {
        books.removeWhere(
                (b) => b['title'] == book.title && b['author'] == book.author);
        await docRef.set({'my_books': books}, SetOptions(merge: true));
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Kitap kaldırıldı.")));
      } else {
        books.add(book.toMap());
        await docRef.set({'my_books': books}, SetOptions(merge: true));
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Kitap eklendi.")));
      }

      setState(() {
        _isBookInLibrary = !_isBookInLibrary;
        _isBookInLibraryChanged = true;
      });
    } catch (e) {
      debugPrint("Firestore hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
