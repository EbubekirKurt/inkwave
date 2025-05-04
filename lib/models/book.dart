class Book {
  final String id; // <— Google Books volumeId
  final String title;
  final String author;
  final String imageUrl;
  final double rating; // Google Books rating
  final String description;
  final double price;
  final String? previewLink;

  // Uygulama içi rating
  final double appRating;
  final int ratingCount;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.rating,
    required this.description,
    required this.price,
    this.previewLink,
    this.appRating = 0.0,
    this.ratingCount = 0,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    final saleInfo = json['saleInfo'] ?? {};
    final id = json['id'] ?? ''; // volumeId

    return Book(
      id: id,
      title: volumeInfo['title'] ?? 'Bilinmeyen Başlık',
      author: (volumeInfo['authors'] != null && volumeInfo['authors'].isNotEmpty)
          ? volumeInfo['authors'][0]
          : 'Bilinmeyen Yazar',
      imageUrl: volumeInfo['imageLinks']?['thumbnail'] ?? '',
      rating: (volumeInfo['averageRating'] ?? 0.0).toDouble(),
      description: volumeInfo['description'] ?? 'Açıklama bulunamadı.',
      price: saleInfo['listPrice'] != null
          ? (saleInfo['listPrice']['amount'] as num).toDouble()
          : 0.0,
      previewLink: volumeInfo['previewLink'],
    );
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Bilinmeyen Başlık',
      author: map['author'] ?? 'Bilinmeyen Yazar',
      imageUrl: map['imageUrl'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      description: map['description'] ?? 'Açıklama bulunamadı.',
      price: (map['price'] ?? 0.0).toDouble(),
      previewLink: map['previewLink'],
      appRating: (map['appRating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'rating': rating,
      'description': description,
      'price': price,
      'previewLink': previewLink,
      'appRating': appRating,
      'ratingCount': ratingCount,
    };
  }
}
