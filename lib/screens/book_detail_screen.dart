import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/models/book.dart';
import 'package:inkwave/screens/webview_screen.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({Key? key}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final book = ModalRoute.of(context)?.settings.arguments as Book?;

    if (book == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Book Details"),
          backgroundColor: AppConstants.primaryColor,
        ),
        body: const Center(
          child: Text("Book details not available", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppConstants.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: AppConstants.primaryColor,
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kitap görseli
              Center(
                child: SizedBox(
                  height: 250,
                  child: book.imageUrl.isNotEmpty
                      ? Image.network(
                    book.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 250, color: Colors.grey),
                  )
                      : const Icon(Icons.book, size: 250, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 20),

              // Başlık
              Text(
                book.title,
                style: AppConstants.headlineStyle.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text('Yazar: ${book.author}', style: AppConstants.subtitleStyle),
              const SizedBox(height: 8),
              Text('Puan: ${book.rating} / 5.0', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),

              // Açıklama kısmı
              _buildExpandableDescription(book.description),

              const SizedBox(height: 30),

              // Kitabı Oku Butonu
              if (book.previewLink != null && book.previewLink!.isNotEmpty)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _openBookPreview(context, book.previewLink!),
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text("Kitabı Oku"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppConstants.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        Text(
          _isDescriptionExpanded ? text : previewText,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _isDescriptionExpanded = !_isDescriptionExpanded;
            });
          },
          child: Text(
            _isDescriptionExpanded ? "Daha az göster ▲" : "Devamını oku... ▼",
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _openBookPreview(BuildContext context, String previewLink) {
    final String bookId = Uri.parse(previewLink).queryParameters['id'] ?? '';
    final String bookReaderUrl = "https://play.google.com/books/reader?id=$bookId&printsec=frontcover";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(url: bookReaderUrl),
      ),
    );
  }
}
