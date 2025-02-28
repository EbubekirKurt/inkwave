import 'package:flutter/material.dart';
import 'package:inkwave/models/book.dart';

class NewestBooksWidget extends StatelessWidget {
  final List<Book> books;

  const NewestBooksWidget({Key? key, required this.books}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];

          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/bookDetail',
                arguments: book,
              );
            },
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: book.imageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(book.imageUrl),
                  fit: BoxFit.cover,
                )
                    : null,
                color: book.imageUrl.isEmpty ? Colors.grey : null,
              ),
              child: book.imageUrl.isEmpty
                  ? const Icon(Icons.broken_image, color: Colors.red)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
