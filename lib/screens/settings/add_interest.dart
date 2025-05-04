import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inkwave/constants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AddInterestsScreen extends StatefulWidget {
  const AddInterestsScreen({Key? key}) : super(key: key);

  @override
  _AddInterestsScreenState createState() => _AddInterestsScreenState();
}

class _AddInterestsScreenState extends State<AddInterestsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _allInterests = [
    "Programlama", "Kişisel Gelişim", "Roman", "Bilim Kurgu", "Psikoloji",
    "Felsefe", "Tarih", "Sanat", "Ekonomi", "Spor", "Diğer",
  ];
  final TextEditingController _otherController = TextEditingController();

  List<String> _selectedInterests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInterests();
  }

  Future<void> _loadUserInterests() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null && doc.data()!.containsKey("interest")) {
          final data = doc["interest"];
          if (data is List) {
            _selectedInterests = List<String>.from(data);
            final others = _selectedInterests.where((e) => !_allInterests.contains(e)).toList();
            if (others.isNotEmpty) {
              _selectedInterests.add("Diğer");
              _otherController.text = others.first;
              _selectedInterests.remove(others.first);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("İlgi alanları yüklenemedi: $e");
      _showError("İlgi alanları yüklenemedi.");
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveInterests() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showError("İnternet bağlantısı yok. Lütfen tekrar deneyin.");
      return;
    }

    List<String> toSave = List.from(_selectedInterests);
    if (toSave.contains("Diğer")) {
      toSave.remove("Diğer");
      if (_otherController.text.trim().isNotEmpty) {
        toSave.add(_otherController.text.trim());
      }
    }

    try {
      await _firestore.collection("users").doc(user.uid).set({
        "interest": toSave,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("İlgi alanların güncellendi.")),
      );
    } catch (e) {
      debugPrint("Kaydetme hatası: $e");
      _showError("Kaydederken bir hata oluştu.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        title: const Text("İlgi Alanlarını Güncelle", style: TextStyle(color: Colors.white)),
        backgroundColor: AppConstants.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: _allInterests.map((interest) {
                return CheckboxListTile(
                  title: Text(interest, style: const TextStyle(color: Colors.white)),
                  value: _selectedInterests.contains(interest),
                  activeColor: Colors.amber,
                  checkColor: Colors.black,
                  onChanged: (bool? val) {
                    setState(() {
                      if (val == true) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),

          if (_selectedInterests.contains("Diğer"))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _otherController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Diğer ilgi alanınızı yazın...",
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _saveInterests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Kaydet", style: TextStyle(color: Colors.black, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
