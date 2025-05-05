import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:inkwave/services/translate_api.dart';

import 'package:excel/excel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';


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

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.amber),
                title: const Text("CSV olarak dışa aktar", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _exportFavoritesToCSV();
                },
              ),
              ListTile(
                leading: const Icon(Icons.grid_on, color: Colors.amberAccent),
                title: const Text("Excel (.xlsx) olarak dışa aktar", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _exportFavoritesToExcel();
                },
              ),
            ],
          ),
        );
      },
    );
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

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _translatedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Çeviri kopyalandı!")),
    );
  }

  Future<void> _pasteFromClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null) {
      setState(() {
        _textController.text = data.text ?? '';
      });
    }
  }

  Future<bool> _requestStoragePermission() async {
    var status = await Permission.storage.status;

    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Depolama izni verilmedi. İşlem iptal edildi.")),
      );
      return false;
    }
  }



  Future<void> _exportFavoritesToExcel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) return;

    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Depolama izni gerekli.")),
        );
        return;
      }
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('translate_history')
        .where('isFavorite', isEqualTo: true)
        .get();

    final excel = Excel.createExcel();
    final sheet = excel['Favorites'];
    sheet.appendRow(['Original', 'Translated', 'From', 'To', 'Timestamp']);

    for (var doc in snapshot.docs) {
      final data = doc.data();
      sheet.appendRow([
        data['original'] ?? '',
        data['translated'] ?? '',
        data['from'] ?? '',
        data['to'] ?? '',
        data['timestamp']?.toDate().toString() ?? '',
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    final dir = Platform.isAndroid
        ? Directory('/storage/emulated/0/Download')
        : await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/favorite_translations.xlsx');
    await file.writeAsBytes(bytes);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Excel dosyası kaydedildi: ${file.path}"),
        action: SnackBarAction(
          label: "Aç",
          textColor: Colors.amber,
          onPressed: () => OpenFile.open(file.path),
        ),
      ),
    );
  }


  void _clearInputText() {
    setState(() {
      _textController.clear();
    });
  }

  void _toggleFavorite(String docId, bool currentStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('translate_history')
        .doc(docId)
        .update({'isFavorite': !currentStatus});
  }

  void _deleteHistory(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('translate_history')
        .doc(docId)
        .delete();
  }

  Future<void> _exportFavoritesToCSV() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('translate_history')
        .where('isFavorite', isEqualTo: true)
        .get();

    final rows = <List<String>>[
      ['Original', 'Translated', 'From', 'To', 'Timestamp'],
    ];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      rows.add([
        data['original'] ?? '',
        data['translated'] ?? '',
        data['from'] ?? '',
        data['to'] ?? '',
        data['timestamp']?.toDate().toString() ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/favorite_translations.csv');
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("CSV dışa aktarıldı: ${file.path}")),
    );
  }

  Future<void> _shareCSVFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/favorite_translations.csv';
    final file = File(path);

    if (await file.exists()) {
      await Share.shareXFiles([XFile(path)], text: "Favori çevirilerim");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("CSV dosyası bulunamadı.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
              child: Column(
                children: [
                  const Text("Metin Çeviri", style: TextStyle(fontSize: 24, color: Colors.white)),
                  const SizedBox(height: 20),
                  _buildTextInputField(),
                  const SizedBox(height: 12),
                  _buildLanguageSelection(),
                  const SizedBox(height: 12),
                  _buildTranslateButton(),
                  const SizedBox(height: 12),
                  _buildTranslationResult(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const TabBar(
                    tabs: [
                      Tab(text: "Tüm Geçmiş"),
                      Tab(text: "Favoriler"),
                    ],
                    labelColor: Colors.amber,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.amber,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTranslationHistory(false),
                        Column(
                          children: [
                            _buildActionButtons(),
                            Expanded(child: _buildTranslationHistory(true)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          onPressed: () => _showExportOptions(context),
          icon: const Icon(Icons.download, color: Colors.amber),
          label: const Text("Dışa Aktar", style: TextStyle(color: Colors.amber)),
        ),
        TextButton.icon(
          onPressed: _shareCSVFile,
          icon: const Icon(Icons.share, color: Colors.greenAccent),
          label: const Text("Paylaş", style: TextStyle(color: Colors.greenAccent)),
        ),
      ],
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
        _buildDropdown(_fromLang, (value) => setState(() => _fromLang = value!)),
        GestureDetector(
          onTap: () => setState(() {
            String tmp = _fromLang;
            _fromLang = _toLang;
            _toLang = tmp;
          }),
          child: const Icon(Icons.swap_horiz, color: Colors.white, size: 30),
        ),
        _buildDropdown(_toLang, (value) => setState(() => _toLang = value!)),
      ],
    );
  }

  Widget _buildTranslateButton() {
    return ElevatedButton.icon(
      onPressed: _translateText,
      icon: const Icon(Icons.translate, color: Colors.white),
      label: const Text("Çevir", style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTranslationResult() {
    if (_translatedText.isEmpty) return const SizedBox();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(_translatedText, style: const TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white54),
            onPressed: _copyToClipboard,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
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

  Widget _buildTranslationHistory(bool showFavoritesOnly) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('translate_history')
          .orderBy('timestamp', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final original = (data['original'] ?? '').toString().toLowerCase();
          final translated = (data['translated'] ?? '').toString().toLowerCase();
          final isFav = data['isFavorite'] ?? false;
          return (original.contains(_searchQuery) || translated.contains(_searchQuery)) &&
              (!showFavoritesOnly || isFav);
        });

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              showFavoritesOnly ? "Favori çeviri yok." : "Geçmiş boş.",
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView(
          children: filtered.map((doc) {
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

  Widget _buildDropdown(String selected, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      dropdownColor: const Color(0xFF2D2D44),
      value: selected,
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
