import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/models/book.dart';

class BuyBooksScreen extends StatelessWidget {
  final Function(int) onBookAdded;

  BuyBooksScreen({Key? key, required this.onBookAdded}) : super(key: key);

  // Artık resim url'lerini asset olarak kullanıyoruz.
  final List<Book> storeBooks = [
    Book(
      title: 'Introduction to Computer Science',
      author: 'I.T.L Education Solutions Limited',
      imageUrl: 'assets/images/etm.jpg',
      rating: 4.0,
      description: 'Temel bilgisayar bilimi konuları.',
      price: 10.0,
    ),
    Book(
      title: 'Encyclopedia of Computer Science',
      author: 'Edwin D. Reilly',
      imageUrl: 'assets/images/etm.jpg',
      rating: 4.5,
      description: 'Bilgisayar bilimleri için kapsamlı bir ansiklopedi.',
      price: 20.0,
    ),
    Book(
      title: 'Computer Science and Computing',
      author: 'Michael Knee',
      imageUrl: 'assets/images/etm.jpg',
      rating: 3.8,
      description: 'Çeşitli bilgisayar ve programlama konuları.',
      price: 15.0,
    ),
  ];

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
              Text("Kitap Satın Al", style: AppConstants.headlineStyle),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: storeBooks.length,
                  itemBuilder: (context, index) {
                    final book = storeBooks[index];
                    return Card(
                      color: Colors.white10,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0), // Padding'i azaltın
                        leading: SizedBox(
                          width: 50,
                          height: 50,
                          child: Image.asset(book.imageUrl, fit: BoxFit.cover),
                        ),
                        title: Text(book.title, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Free • ⭐ ${book.rating.toStringAsFixed(1)}',
                          style: AppConstants.subtitleStyle,
                        ),
                      ),

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
