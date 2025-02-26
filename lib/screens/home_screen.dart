import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/models/book.dart';
import 'package:inkwave/widgets/newest_books_widget.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);

  final List<Book> books = [
    Book(
      title: 'XNA 3.0 Game Programming Recipes',
      author: 'Renear Grigajus',
      imageUrl: 'assets/images/xna.jpeg',
      rating: 4.0,
      description: 'A problem-solution approach to XNA 3.0 game programming.',
      price: 0.0,
    ),
    Book(
      title: 'Gamers at Work',
      author: 'Morgan Ramsay',
      imageUrl: 'assets/images/gaw.jpeg',
      rating: 4.2,
      description: 'Stories behind the games people play.',
      price: 0.0,
    ),
    Book(
      title: 'IT Expert Level',
      author: 'John Doe',
      imageUrl: 'assets/images/etm.jpg',
      rating: 3.5,
      description: 'The advanced concepts of IT domain.',
      price: 0.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Inkwave", style: AppConstants.headlineStyle),
              const SizedBox(height: 20),
              // Yatay kaydırılabilir en yeni kitaplar
              NewestBooksWidget(books: books),
              const SizedBox(height: 20),
              Text("Newest Books", style: AppConstants.headlineStyle),
              const SizedBox(height: 10),
              // Dikey liste (Kitap isimleri, rating vb.)
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
                      child: Image.asset(book.imageUrl, fit: BoxFit.cover),
                    ),
                    title: Text(book.title, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      'Free • ⭐ ${book.rating.toStringAsFixed(1)}',
                      style: AppConstants.subtitleStyle,
                    ),
                    onTap: () {
                      // Kitap detay sayfasına git
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
    );
  }
}
