import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inkwave/services/translate_api.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({Key? key}) : super(key: key);

  @override
  _TranslateScreenState createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _translatedText = "";
  String _fromLang = "en";
  String _toLang = "tr";
  String _searchQuery = "";
  List<Map<String, String>> _languages = [];

  @override
  void initState() {
    super.initState();
    _fetchLanguages();
  }

  void _fetchLanguages() async {
    final languages = await TranslateApi.getLanguages();
    setState(() {
      _languages = languages;
    });
  }

  void _translateText() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bir metin girin!")),
      );
      return;
    }

    setState(() {
      _translatedText = "Çevriliyor...";
    });

    try {
      final translated = await TranslateApi.translateText(
        _textController.text.trim(),
        _fromLang,
        _toLang,
      );

      setState(() {
        _translatedText = translated;
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('translate_history')
            .add({
          'original': _textController.text.trim(),
          'translated': translated,
          'from': _fromLang,
          'to': _toLang,
          'timestamp': FieldValue.serverTimestamp(),
          'isFavorite': false,
        });
      }
    } catch (e) {
      setState(() {
        _translatedText = "Çeviri başarısız!";
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null) {
      setState(() {
        _textController.text = clipboardData.text!;
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _translatedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Çeviri kopyalandı!")),
    );
  }

  void _clearInputText() {
    setState(() {
      _textController.clear();
    });
  }

  void _toggleFavorite(String docId, bool currentStatus) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('translate_history')
        .doc(docId)
        .update({'isFavorite': !currentStatus});
  }

  void _deleteHistory(String docId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('translate_history')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Metin Çeviri",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextInputField(),
                  const SizedBox(height: 16),
                  _buildLanguageSelection(),
                  const SizedBox(height: 16),
                  _buildTranslateButton(),
                  const SizedBox(height: 16),
                  _buildTranslationResult(),
                  const SizedBox(height: 24),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildTranslationHistory(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Çevirmek istediğiniz metni yazın...",
                hintStyle: TextStyle(color: Colors.white54),
              ),
              maxLines: 3,
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.paste, color: Colors.white54),
                onPressed: _pasteFromClipboard,
              ),
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: _clearInputText,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDropdown(_fromLang, (value) {
          setState(() {
            _fromLang = value!;
          });
        }),
        GestureDetector(
          onTap: () {
            setState(() {
              String temp = _fromLang;
              _fromLang = _toLang;
              _toLang = temp;
            });
          },
          child: const Icon(Icons.swap_horiz, color: Colors.white, size: 30),
        ),
        _buildDropdown(_toLang, (value) {
          setState(() {
            _toLang = value!;
          });
        }),
      ],
    );
  }

  Widget _buildTranslateButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _translateText,
        icon: const Icon(Icons.translate, color: Colors.white),
        label: const Text("Çevir", style: TextStyle(fontSize: 18, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildTranslationResult() {
    return AnimatedOpacity(
      opacity: _translatedText.isEmpty ? 0 : 1,
      duration: const Duration(milliseconds: 500),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _translatedText,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white54),
              onPressed: _copyToClipboard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Geçmişte ara...",
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildTranslationHistory() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('translate_history')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final docs = snapshot.data!.docs;

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final original = (data['original'] ?? '').toString().toLowerCase();
          final translated = (data['translated'] ?? '').toString().toLowerCase();
          return original.contains(_searchQuery) || translated.contains(_searchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Text("Çeviri geçmişi bulunamadı.", style: TextStyle(color: Colors.white70));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: filteredDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isFav = data['isFavorite'] ?? false;

            return ListTile(
              title: Text(data['original'] ?? '', style: const TextStyle(color: Colors.white)),
              subtitle: Text(data['translated'] ?? '', style: const TextStyle(color: Colors.white70)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      color: isFav ? Colors.amber : Colors.white54,
                    ),
                    onPressed: () => _toggleFavorite(doc.id, isFav),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteHistory(doc.id),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDropdown(String selectedValue, Function(String?) onChanged) {
    return DropdownButton<String>(
      dropdownColor: const Color(0xFF2D2D44),
      value: selectedValue,
      items: _languages.map((lang) {
        return DropdownMenuItem(
          value: lang["code"],
          child: Text(lang["name"]!, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
      underline: Container(),
    );
  }
}
