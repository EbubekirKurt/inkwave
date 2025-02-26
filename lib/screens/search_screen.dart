import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({Key? key}) : super(key: key);

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
              Text("Kitap Ara", style: AppConstants.headlineStyle),
              const SizedBox(height: 20),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white10,
                  hintText: 'Kitap veya yazar ara...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 20),
              // Arama sonuçları ListView vb. koyabilirsiniz
              Expanded(
                child: Center(
                  child: Text("Arama sonuçları burada listelenecek...",
                      style: AppConstants.subtitleStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
