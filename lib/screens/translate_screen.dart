import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkwave/services/translate_api.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({Key? key}) : super(key: key);

  @override
  _TranslateScreenState createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextEditingController _textController = TextEditingController();
  String _translatedText = "";
  String _fromLang = "en";
  String _toLang = "tr";
  List<Map<String, String>> _languages = [];

  @override
  void initState() {
    super.initState();
    _fetchLanguages();
  }

  /// **📌 Desteklenen dilleri getir**
  void _fetchLanguages() async {
    final languages = await TranslateApi.getLanguages();
    setState(() {
      _languages = languages;
    });
  }

  /// **📌 Metni çevir**
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

      print("✅ Doğru Çeviri Sonucu: $translated");

    } catch (e) {
      setState(() {
        _translatedText = "Çeviri başarısız!";
      });
    }
  }

  /// **📌 Panodan Yapıştırma**
  Future<void> _pasteFromClipboard() async {
    ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null) {
      setState(() {
        _textController.text = clipboardData.text!;
      });
    }
  }

  /// **📌 Çeviri Metnini Kopyalama**
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _translatedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Çeviri kopyalandı!")),
    );
  }

  /// **📌 Giriş Metnini Temizleme**
  void _clearInputText() {
    setState(() {
      _textController.clear();
    });
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

                // **Giriş Alanı**
                _buildTextInputField(),

                const SizedBox(height: 16),

                // **Dil Seçim Alanı**
                _buildLanguageSelection(),

                const SizedBox(height: 16),

                // **Çeviri Butonu**
                _buildTranslateButton(),

                const SizedBox(height: 16),

                // **Çeviri Sonucu**
                _buildTranslationResult(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// **📌 Metin giriş alanı**
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

  /// **📌 Dil seçme alanı**
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

  /// **📌 Çeviri butonu**
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

  /// **📌 Çeviri Sonucu**
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
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white54),
                  onPressed: _copyToClipboard,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// **📌 Dropdown (Dil Seçimi)**
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
