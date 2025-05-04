import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/screens/login.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class EditPersonalDetailsScreen extends StatefulWidget {
  const EditPersonalDetailsScreen({Key? key}) : super(key: key);

  @override
  State<EditPersonalDetailsScreen> createState() => _EditPersonalDetailsScreenState();
}

class _EditPersonalDetailsScreenState extends State<EditPersonalDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  String _selectedCountryCode = "+90";
  final List<String> _countryCodes = ["+90", "+1", "+44", "+49", "+33", "+91"];

  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController nationalityController = TextEditingController();
  final TextEditingController totalBooksController = TextEditingController();
  final TextEditingController leaderboardScoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_user == null) return;

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        nameController.text = data['name'] ?? '';
        surnameController.text = data['surname'] ?? '';
        birthdayController.text = data['birthday'] ?? '';
        nationalityController.text = data['nationality'] ?? '';
        totalBooksController.text = data['total_book_count']?.toString() ?? '0';
        leaderboardScoreController.text = data['leaderboard_score']?.toString() ?? '0';

        final fullPhone = data['phone_number'] ?? '';
        for (String code in _countryCodes) {
          if (fullPhone.startsWith(code)) {
            _selectedCountryCode = code;
            phoneController.text = fullPhone.substring(code.length);
            break;
          }
        }
      }
    } catch (e) {
      debugPrint("Kullanıcı verisi alınamadı: $e");
      _showError("Kullanıcı bilgileri alınamadı.");
    }
  }

  Future<void> _saveUserData() async {
    if (_user == null) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showError("İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.");
      return;
    }

    try {
      await _firestore.collection('users').doc(_user!.uid).set({
        'uid': _user!.uid,
        'name': nameController.text.trim(),
        'surname': surnameController.text.trim(),
        'phone_number': _selectedCountryCode + phoneController.text.trim(),
        'birthday': birthdayController.text.trim(),
        'nationality': nationalityController.text.trim(),
        'total_book_count': int.tryParse(totalBooksController.text.trim()) ?? 0,
        'leaderboard_score': double.tryParse(leaderboardScoreController.text.trim()) ?? 0.0,
        'email': _user!.email ?? '',
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil güncellendi")),
      );
    } catch (e) {
      debugPrint("Veri kaydederken hata: $e");
      _showError("Bilgiler kaydedilemedi. Lütfen tekrar deneyin.");
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().disconnect();
      await GoogleSignIn().signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      debugPrint("Çıkış hatası: $e");
      _showError("Çıkış yapılamadı.");
    }
  }

  void _pickDate() async {
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime(2000),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );

      if (picked != null) {
        birthdayController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      }
    } catch (e) {
      debugPrint("Tarih seçme hatası: $e");
      _showError("Tarih seçilemedi.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text("Kişisel Bilgiler", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildField("Ad", nameController),
            _buildField("Soyad", surnameController),
            _buildField("Email", TextEditingController(text: _user?.email ?? ''), readOnly: true),

            const SizedBox(height: 10),
            const Align(alignment: Alignment.centerLeft, child: Text("Telefon", style: TextStyle(color: Colors.grey))),
            Row(
              children: [
                DropdownButton<String>(
                  value: _selectedCountryCode,
                  onChanged: (val) {
                    setState(() => _selectedCountryCode = val!);
                  },
                  items: _countryCodes.map((code) {
                    return DropdownMenuItem(
                      value: code,
                      child: Text(code),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 10),
                Expanded(child: _buildField("", phoneController)),
              ],
            ),

            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(child: _buildField("Doğum Tarihi", birthdayController)),
            ),
            _buildField("Uyruk", nationalityController),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveUserData,
              child: const Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool isNumeric = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
