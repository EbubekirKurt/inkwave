import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/models/book.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({Key? key}) : super(key: key);

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
        title: Text(book.title),
        backgroundColor: AppConstants.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: AppConstants.primaryColor,
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 250,
                child: Image.asset(
                  book.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, size: 250, color: Colors.grey);
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(book.title, style: AppConstants.headlineStyle),
              const SizedBox(height: 8),
              Text('Yazar: ${book.author}', style: AppConstants.subtitleStyle),
              const SizedBox(height: 8),
              Text('Puan: ${book.rating} / 5.0', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              Text(book.description, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text("Geri Dön"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
