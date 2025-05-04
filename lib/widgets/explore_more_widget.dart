import 'package:flutter/material.dart';
import 'package:inkwave/models/book.dart';
import 'package:inkwave/constants.dart';

class ExploreMoreWidget extends StatelessWidget {
  final List<Book> books;

  const ExploreMoreWidget({Key? key, required this.books}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Text("Keşfet", style: AppConstants.headlineStyle),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];

              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/bookDetail', arguments: book),
                child: Card(
                  color: Colors.white10,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 12 : 8,
                    right: index == books.length - 1 ? 12 : 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 150,
                            width: 130,
                            child: book.imageUrl.isNotEmpty
                                ? Image.network(book.imageUrl, fit: BoxFit.cover)
                                : const Icon(Icons.menu_book, size: 40, color: Colors.white54),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            book.title,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '⭐ ${book.rating.toStringAsFixed(1)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
