class Book {
  final String title;
  final String author;
  final String imageUrl;
  final double rating;
  final String description;
  final double price;
  final String? previewLink; // Kitap önizlemesi için eklendi

  Book({
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.rating,
    required this.description,
    required this.price,
    this.previewLink,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'];
    final saleInfo = json['saleInfo'];

    return Book(
      title: volumeInfo['title'] ?? 'Bilinmeyen Başlık',
      author: (volumeInfo['authors'] != null && volumeInfo['authors'].isNotEmpty)
          ? volumeInfo['authors'][0]
          : 'Bilinmeyen Yazar',
      imageUrl: volumeInfo['imageLinks']?['thumbnail'] ?? '',
      rating: volumeInfo['averageRating']?.toDouble() ?? 0.0,
      description: volumeInfo['description'] ?? 'Açıklama bulunamadı.',
      price: saleInfo['listPrice'] != null ? (saleInfo['listPrice']['amount'] as num).toDouble() : 0.0,
      previewLink: volumeInfo['previewLink'],
    );
  }
}
