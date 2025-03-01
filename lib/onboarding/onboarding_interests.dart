import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/onboarding/onboarding_finish.dart';

class OnboardingInterestsScreen extends StatefulWidget {
  const OnboardingInterestsScreen({Key? key}) : super(key: key);

  @override
  _OnboardingInterestsScreenState createState() => _OnboardingInterestsScreenState();
}

class _OnboardingInterestsScreenState extends State<OnboardingInterestsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedInterest = "";
  bool _isLoading = true;

  final List<String> _interests = [
    "Programlama", "Kişisel Gelişim", "Roman", "Bilim Kurgu", "Psikoloji",
    "Felsefe", "Tarih", "Sanat", "Ekonomi", "Spor",
  ];

  @override
  void initState() {
    super.initState();
    _checkInterest();
  }

  /// **Kullanıcının Firestore'da ilgi alanı olup olmadığını kontrol eder.**
  Future<void> _checkInterest() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey("interest") && data["interest"].isNotEmpty) {
          // Kullanıcı zaten ilgi alanı seçmişse, doğrudan sonraki ekrana geç
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const OnboardingFinishScreen()));
          return;
        }
      }
    } catch (e) {
      print("Firestore'dan veri çekerken hata oluştu: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// **Seçilen ilgi alanını Firestore’a kaydeder.**
  Future<void> _saveInterest() async {
    User? user = _auth.currentUser;
    if (user == null || _selectedInterest.isEmpty) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        "interest": _selectedInterest,
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("interest_selected", true);

      // İlgi alanı kaydedildikten sonra onboarding'in bir sonraki ekranına yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingFinishScreen()),
      );
    } catch (e) {
      print("Firestore'a ilgi alanı kaydedilirken hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text("İlgi Alanını Seç", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Icon(Icons.book, size: 100, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text("En çok ilgilendiğin alanı seç:",
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
          const SizedBox(height: 20),

          // İlgi alanları listesi
          Expanded(
            child: ListView.builder(
              itemCount: _interests.length,
              itemBuilder: (context, index) {
                return RadioListTile<String>(
                  title: Text(_interests[index], style: const TextStyle(color: Colors.white)),
                  value: _interests[index],
                  groupValue: _selectedInterest,
                  activeColor: Colors.amber,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedInterest = value!;
                    });
                  },
                );
              },
            ),
          ),

          // Kaydet Butonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedInterest.isEmpty ? null : _saveInterest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Devam Et", style: TextStyle(fontSize: 18, color: Colors.black)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
