import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inkwave/constants.dart';
import 'package:inkwave/screens/login.dart';
import 'package:inkwave/widgets/settings_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  String _selectedCountryCode = "+90";
  final List<String> _countryCodes = [
    "+1", "+7", "+20", "+27", "+30", "+31", "+32", "+33", "+34", "+36", "+39",
    "+40", "+41", "+43", "+44", "+45", "+46", "+47", "+48", "+49", "+51", "+52",
    "+53", "+54", "+55", "+56", "+57", "+58", "+60", "+61", "+62", "+63", "+64",
    "+65", "+66", "+81", "+82", "+84", "+86", "+90", "+91", "+92", "+93", "+94",
    "+95", "+98", "+212", "+213", "+216", "+218", "+220", "+221", "+222", "+223",
    "+224", "+225", "+226", "+227", "+228", "+229", "+230", "+231", "+232", "+233",
    "+234", "+235", "+236", "+237", "+238", "+239", "+240", "+241", "+242", "+243",
    "+244", "+245", "+246", "+248", "+249", "+250", "+251", "+252", "+253", "+254",
    "+255", "+256", "+257", "+258", "+260", "+261", "+262", "+263", "+264", "+265",
    "+266", "+267", "+268", "+269", "+290", "+291", "+297", "+298", "+299",
  ];

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
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

        nameController.text = data['name'] ?? "";
        surnameController.text = data['surname'] ?? "";
        nationalityController.text = data['nationality'] ?? "";
        birthdayController.text = data['birthday'] ?? "";
        totalBooksController.text = data['total_book_count']?.toString() ?? "0";
        leaderboardScoreController.text = data['leaderboard_score']?.toString() ?? "0";

        String fullPhoneNumber = data['phone_number'] ?? "";
        for (String code in _countryCodes) {
          if (fullPhoneNumber.startsWith(code)) {
            _selectedCountryCode = code;
            phoneController.text = fullPhoneNumber.substring(code.length);
            break;
          }
        }
      }
    } catch (e) {
      print("Firestore veri çekme hatası: $e");
    }
  }

  Future<void> _saveUserData() async {
    if (_user == null) return;

    try {
      await _firestore.collection('users').doc(_user!.uid).set({
        "uid": _user!.uid,
        "name": nameController.text.trim(),
        "surname": surnameController.text.trim(),
        "phone_number": _selectedCountryCode + phoneController.text.trim(),
        "birthday": birthdayController.text.trim(),
        "nationality": nationalityController.text.trim(),
        "total_book_count": int.tryParse(totalBooksController.text.trim()) ?? 0,
        "leaderboard_score": double.tryParse(leaderboardScoreController.text.trim()) ?? 0.0,
        "email": _user!.email ?? "no-email",
        "created_at": FieldValue.serverTimestamp(),
        "user_type_id": "/user_types/96LYlKLni2rMImmRLh1k",
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil başarıyla güncellendi!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().disconnect();
    await GoogleSignIn().signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppConstants.primaryColor,
        appBar: AppBar(
          backgroundColor: AppConstants.primaryColor,
          title: const Text("Profilim", style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => SettingsDrawer.show(context, _signOut),
              tooltip: "Ayarlar",
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Icon(Icons.account_circle, size: 100, color: Colors.white),
              ),
              const SizedBox(height: 20),

              _buildEditableField("Ad", nameController),
              _buildEditableField("Soyad", surnameController),
              _buildProfileInfo("Email", _user?.email ?? "Yok"),

              const Text("Telefon", style: TextStyle(color: Colors.grey, fontSize: 16)),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedCountryCode,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCountryCode = newValue!;
                      });
                    },
                    items: _countryCodes.map((String code) {
                      return DropdownMenuItem<String>(
                        value: code,
                        child: Text(code, style: const TextStyle(color: Colors.black)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _buildEditableField("", phoneController)),
                ],
              ),

              _buildEditableField("Doğum Tarihi", birthdayController),
              _buildEditableField("Uyruk", nationalityController),
              _buildEditableField("Toplam Okunan Kitap", totalBooksController, isNumeric: true),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveUserData,
                child: const Text("Kaydet"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {bool isNumeric = false, bool isReadOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        readOnly: isReadOnly,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(String label, String value) {
    return _buildEditableField(label, TextEditingController(text: value), isReadOnly: true);
  }
}
