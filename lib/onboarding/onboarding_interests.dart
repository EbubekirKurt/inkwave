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

  final List<String> _interests = [
    "Programlama", "Kişisel Gelişim", "Roman", "Bilim Kurgu", "Psikoloji",
    "Felsefe", "Tarih", "Sanat", "Ekonomi", "Spor", "Diğer",
  ];
  final List<String> _selectedInterests = [];
  final TextEditingController _otherController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyCompleted();
  }

  Future<void> _checkIfAlreadyCompleted() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null &&
          data['name'] != null &&
          data['surname'] != null &&
          data['interest'] != null &&
          (data['interest'] as List).isNotEmpty) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingFinishScreen()),
        );
        return;
      }
    } catch (e) {
      print("Kullanıcı verisi kontrol edilirken hata oluştu: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveInterest() async {
    final user = _auth.currentUser;
    if (user == null || _selectedInterests.isEmpty) return;

    final interestsToSave = List<String>.from(_selectedInterests);
    if (_selectedInterests.contains("Diğer") && _otherController.text.trim().isNotEmpty) {
      interestsToSave.add(_otherController.text.trim());
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        "interest": interestsToSave,
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("interest_selected", true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingFinishScreen()),
      );
    } catch (e) {
      print("İlgi alanı kaydedilirken hata oluştu: $e");
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
          const Center(child: Icon(Icons.book, size: 100, color: Colors.white)),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text("İlgilendiğin alanları seç (birden fazla seçebilirsin):",
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              itemCount: _interests.length,
              itemBuilder: (context, index) {
                final interest = _interests[index];
                final isSelected = _selectedInterests.contains(interest);
                return CheckboxListTile(
                  title: Text(interest, style: const TextStyle(color: Colors.white)),
                  value: isSelected,
                  activeColor: Colors.amber,
                  checkColor: Colors.black,
                  onChanged: (bool? selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                );
              },
            ),
          ),

          if (_selectedInterests.contains("Diğer"))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _otherController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Diğer ilgi alanınızı yazınız...",
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedInterests.isEmpty ? null : _saveInterest,
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
