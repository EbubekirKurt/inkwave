import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/models/book.dart';

class LibraryScreen extends StatelessWidget {
  final List<int> bookIndexes;

  LibraryScreen({Key? key, required this.bookIndexes}) : super(key: key);

  final List<Book> storeBooks = [
    Book(
      title: 'Introduction to Computer Science',
      author: 'I.T.L Education Solutions Limited',
      // Yerel resim yolu
      imageUrl: 'assets/images/etm.jpg',
      rating: 4.0,
      description: 'Temel bilgisayar bilimi konuları.',
      price: 10.0,
    ),
    Book(
      title: 'Encyclopedia of Computer Science',
      author: 'Edwin D. Reilly',
      // Yerel resim yolu
      imageUrl: 'assets/images/etm.jpg',
      rating: 4.5,
      description: 'Bilgisayar bilimleri için kapsamlı bir ansiklopedi.',
      price: 20.0,
    ),
    Book(
      title: 'Computer Science and Computing',
      author: 'Michael Knee',
      // Yerel resim yolu
      imageUrl: 'assets/images/etm.jpg',
      rating: 3.8,
      description: 'Çeşitli bilgisayar ve programlama konuları.',
      price: 15.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final myLibrary = bookIndexes.map((index) => storeBooks[index]).toList();

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppConstants.primaryColor,
        body: Padding(
          padding: const EdgeInsets.all(AppConstants.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Kitaplığım", style: AppConstants.headlineStyle),
              const SizedBox(height: 20),
              Expanded(
                child: myLibrary.isEmpty
                    ? Center(
                  child: Text(
                    "Kitaplığınız boş. Kitap satın alın!",
                    style: AppConstants.subtitleStyle,
                  ),
                )
                    : ListView.builder(
                  itemCount: myLibrary.length,
                  itemBuilder: (context, index) {
                    final book = myLibrary[index];
                    return Card(
                      color: Colors.white10,
                      child: ListTile(
                        // Image.network yerine artık Image.asset
                        leading: Image.asset(
                          book.imageUrl,
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                        ),
                        title: Text(
                          book.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Fiyat: \$${book.price} • ⭐ ${book.rating.toStringAsFixed(1)}',
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
