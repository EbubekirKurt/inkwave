import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/screens/home_screen.dart';
import '../main.dart';

class OnboardingFinishScreen extends StatefulWidget {
  const OnboardingFinishScreen({Key? key}) : super(key: key);

  @override
  _OnboardingFinishScreenState createState() => _OnboardingFinishScreenState();
}

class _OnboardingFinishScreenState extends State<OnboardingFinishScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController phoneBodyController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController nationalityController = TextEditingController();

  String _phonePrefix = "+90";
  bool _isSaving = false;

  void _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        birthdayController.text =
        "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
      });
    }
  }

  Future<void> _saveUserData() async {
    setState(() {
      _isSaving = true;
    });

    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        "uid": user.uid,
        "name": nameController.text.trim(),
        "surname": surnameController.text.trim(),
        "phone_number": "$_phonePrefix ${phoneBodyController.text.trim()}",
        "birthday": birthdayController.text.trim(),
        "nationality": nationalityController.text.trim(),
        "email": user.email ?? "",
        "created_at": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } catch (e) {
      print("Firestore'a kaydetme hatası: $e");
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text("Hesabınızı Tamamlayın", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.account_circle, size: 100, color: Colors.white),
            const SizedBox(height: 20),

            _buildTextField("Ad", nameController),
            _buildTextField("Soyad", surnameController),

            // Alan Kodu ve Telefon
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _phonePrefix,
                    dropdownColor: Colors.grey[900],
                    items: ["+90", "+1", "+44", "+49"].map((code) {
                      return DropdownMenuItem(
                        value: code,
                        child: Text(code, style: TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _phonePrefix = val!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Alan Kodu",
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: _buildTextField("Telefon Numarası", phoneBodyController),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Doğum Günü Seçimi
            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: _buildTextField("Doğum Günü", birthdayController),
              ),
            ),

            _buildTextField("Milliyet", nationalityController),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveUserData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Tamamla", style: TextStyle(fontSize: 18, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isReadOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
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
}
