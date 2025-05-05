import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/models/book.dart';
import 'package:inkwave/screens/webview_screen.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({Key? key}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Book? book;
  double _userRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _hasRatedBefore = false;
  bool _isBookInLibrary = false;
  bool _isSaving = false;
  bool _isBookInLibraryChanged = false;
  bool _isDescriptionExpanded = false;
  List<Map<String, dynamic>> _comments = [];
  bool _hasReadThisBook = false;
  int _earnedPointsFromBook = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Book) {
        setState(() => book = args);
        _checkIfBookIsInLibrary(args);
        _checkIfBookWasRead(args);
        _loadUserRating(args.id);
      }
    });
  }

  Future<void> _checkIfBookIsInLibrary(Book book) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _firestore.collection("users").doc(user.uid).get();
    final data = doc.data();
    final books = data?['my_books'] ?? [];
    final exists = books.any((b) => b['title'] == book.title && b['author'] == book.author);
    setState(() => _isBookInLibrary = exists);
  }

  Future<void> _checkIfBookWasRead(Book book) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection("users").doc(user.uid).get();
    final data = doc.data() ?? {};
    final List booksRead = data['books_read'] ?? [];

    final existing = booksRead.firstWhere(
          (b) => (b['id'] != null && b['id'] == book.id),
      orElse: () => null,
    );

    if (existing != null) {
      setState(() {
        _hasReadThisBook = true;
        _earnedPointsFromBook = (existing['earned_points'] ?? 0).toInt();
      });
    }
  }

  Future<void> _toggleBookInLibrary(Book book) async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);
    final docRef = _firestore.collection("users").doc(user.uid);
    final doc = await docRef.get();
    List books = doc.data()?['my_books'] ?? [];

    if (_isBookInLibrary) {
      books.removeWhere((b) => b['title'] == book.title && b['author'] == book.author);
    } else {
      books.add(book.toMap());
    }

    await docRef.set({'my_books': books}, SetOptions(merge: true));
    setState(() {
      _isBookInLibrary = !_isBookInLibrary;
      _isBookInLibraryChanged = true;
      _isSaving = false;
    });
  }

  Future<void> _loadUserRating(String bookId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _firestore.collection('book_ratings').doc(bookId).collection('users').doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        _hasRatedBefore = true;
        _userRating = (doc['rating'] ?? 0.0).toDouble();
        _commentController.text = doc['comment'] ?? '';
      });
    }
    await _loadAllComments(bookId);
  }

  Future<void> _loadAllComments(String bookId) async {
    final snapshot = await _firestore
        .collection('book_ratings')
        .doc(bookId)
        .collection('users')
        .orderBy('timestamp', descending: true)
        .get();
    setState(() {
      _comments = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> _submitRating(Book book) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final comment = _commentController.text.trim();
    await _firestore.collection('book_ratings').doc(book.id).collection('users').doc(user.uid).set({
      'rating': _userRating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
      'userEmail': user.email,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yorum ve puan kaydedildi")));
    await _loadAllComments(book.id);
  }

  void _openBookPreview(String previewLink) {
    final bookId = Uri.parse(previewLink).queryParameters['id'] ?? '';
    final bookReaderUrl = "https://play.google.com/books/reader?id=$bookId&printsec=frontcover";
    Navigator.push(context, MaterialPageRoute(builder: (_) => WebViewScreen(url: bookReaderUrl)));
  }

  Future<void> _toggleReadStatus(Book book) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection("users").doc(user.uid);
    final snapshot = await docRef.get();
    final data = snapshot.data() ?? {};

    List booksRead = List.from(data['books_read'] ?? []);
    int total = (data['total_book_count'] ?? 0).toInt();
    int score = (data['leaderboard_score'] ?? 0).toInt();

    if (_hasReadThisBook) {
      // Geri al
      booksRead.removeWhere((b) => b['id'] == book.id);
      total = total > 0 ? total - 1 : 0;
      score = score - _earnedPointsFromBook;
      if (score < 0) score = 0;
      await docRef.set({
        'books_read': booksRead,
        'total_book_count': total,
        'leaderboard_score': score,
      }, SetOptions(merge: true));
      setState(() {
        _hasReadThisBook = false;
        _earnedPointsFromBook = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kitap 'okunmadı' olarak işaretlendi. Puan geri alındı.")));
    } else {
      final int earned = (Random().nextInt(10) + 3) * 50;
      final bookMap = book.toMap();
      bookMap['earned_points'] = earned;
      booksRead.add(bookMap);
      await docRef.set({
        'books_read': booksRead,
        'total_book_count': total + 1,
        'leaderboard_score': score + earned,
      }, SetOptions(merge: true));
      setState(() {
        _hasReadThisBook = true;
        _earnedPointsFromBook = earned;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kitap okundu olarak işaretlendi! +$earned puan")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        title: Text(book?.title ?? "Kitap", style: const TextStyle(color: Colors.white)),
        backgroundColor: AppConstants.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isBookInLibrary ? Icons.delete : Icons.favorite),
            tooltip: _isBookInLibrary ? "Kitaplıktan Kaldır" : "Kitaplığa Ekle",
            onPressed: () => _toggleBookInLibrary(book!),
          ),
          if (book?.previewLink != null && book!.previewLink!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.menu_book),
              tooltip: "Kitabı Oku",
              onPressed: () => _openBookPreview(book!.previewLink!),
            ),
          IconButton(
            icon: Icon(_hasReadThisBook ? Icons.undo : Icons.check_circle),
            tooltip: _hasReadThisBook ? "Okunmadı olarak işaretle" : "Kitabı Bitirdim",
            onPressed: () => _toggleReadStatus(book!),
          ),
        ],
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
                child: book!.imageUrl.isNotEmpty
                    ? Image.network(book!.imageUrl, height: 220)
                    : const Icon(Icons.book, size: 220, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(book!.title, style: AppConstants.headlineStyle.copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              Text('Yazar: ${book!.author}', style: AppConstants.subtitleStyle),
              const SizedBox(height: 8),
              Text('Puan: ${book!.rating} / 5.0', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              _buildExpandableDescription(book!.description),
              const SizedBox(height: 30),
              const Text("Puanla ve Yorum Yap", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      _userRating >= starIndex ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => _userRating = starIndex.toDouble()),
                  );
                }),
              ),
              TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Yorumunuzu yazın...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _submitRating(book!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_hasRatedBefore ? "Yorumu Güncelle" : "Yorumu Gönder",
                    style: const TextStyle(color: Colors.black)),
              ),
              const SizedBox(height: 30),
              const Text("Yorumlar", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._comments.map((comment) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment['userEmail'] ?? 'Anonim',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < (comment['rating'] ?? 0) ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text(comment['comment'] ?? '', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              )),
            ],
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
    final previewText = text.substring(0, previewMaxLength) + "...";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_isDescriptionExpanded ? text : previewText, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
          child: Text(
            _isDescriptionExpanded ? "Daha az göster ▲" : "Devamını oku... ▼",
            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
