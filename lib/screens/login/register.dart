import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inkwave/screens/home_screen.dart';
import 'package:inkwave/widgets/terms_of_service.dart';
import 'package:inkwave/screens/login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late RiveAnimationController _controller;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isTermsAccepted = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = SimpleAnimation("idle");
  }

  void _togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
      _controller = SimpleAnimation(isPasswordVisible ? "hands_down" : "hands_up");
    });
  }

  Future<void> _register() async {
    setState(() {
      errorMessage = '';
    });

    if (!isTermsAccepted) {
      setState(() {
        _controller = SimpleAnimation("fail");
        errorMessage = "Kullanım şartlarını kabul etmelisiniz!";
      });
      return;
    }

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      setState(() {
        _controller = SimpleAnimation("fail");
        errorMessage = "Tüm alanlar zorunludur!";
      });
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        _controller = SimpleAnimation("fail");
        errorMessage = "Şifreler uyuşmuyor!";
      });
      return;
    }

    try {
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception("Kullanıcı oluşturulamadı! Tekrar deneyin.");
      }

      await _saveUserToFirestore(user);

      setState(() {
        _controller = SimpleAnimation("success");
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _controller = SimpleAnimation("fail");
        errorMessage = _handleFirebaseError(e.code);
      });
    } catch (e) {
      setState(() {
        errorMessage = "Beklenmedik bir hata oluştu: $e";
      });
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "uid": user.uid,
        "name": "Unknown",
        "surname": "",
        "email": user.email ?? "no-email",
        "phone_number": "",
        "birthday": "",
        "nationality": "",
        "preferred_language": "English",
        "total_book_count": 0,
        "weekly_book_count": 0,
        "leaderboard_score": 0.0,
        "user_type_id": "/user_types/96LYlKLni2rMImmRLh1k",
        "created_at": FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint("Firestore'a eklerken hata oluştu: $error");
      rethrow;
    }
  }

  String _handleFirebaseError(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return "Bu e-posta zaten kayıtlı!";
      case 'invalid-email':
        return "E-posta formatı geçersiz!";
      case 'weak-password':
        return "Şifreniz en az 6 karakter olmalı!";
      default:
        return "Bir hata oluştu, lütfen tekrar deneyin.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090617),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 250,
            child: RiveAnimation.asset(
              "assets/rivs/teddy.riv",
              fit: BoxFit.contain,
              controllers: [_controller],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                _buildTextField(emailController, "Email", Icons.email, false),
                const SizedBox(height: 15),
                _buildTextField(passwordController, "Password", Icons.lock, true),
                const SizedBox(height: 15),
                _buildTextField(confirmPasswordController, "Confirm Password", Icons.lock_outline, true),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Checkbox(
                      value: isTermsAccepted,
                      activeColor: Colors.amber,
                      onChanged: (value) {
                        setState(() {
                          isTermsAccepted = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TermsOfServicesScreen()),
                          );
                        },
                        child: const Text.rich(
                          TextSpan(
                            text: "Kayıt olarak ",
                            style: TextStyle(color: Colors.white),
                            children: [
                              TextSpan(
                                text: "Kullanım Şartları",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                              TextSpan(text: "'nı kabul etmiş olursunuz."),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 20),
                _buildSignUpButton(),
                const SizedBox(height: 30),

                // 🔹 Giriş yap bölümü
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Zaten bir hesabın var mı? ",
                      style: TextStyle(color: Colors.white70),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        "Giriş Yap",
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String hint,
      IconData icon,
      bool obscure,
      ) {
    return TextField(
      controller: controller,
      obscureText: obscure ? !isPasswordVisible : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: obscure
            ? IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          onPressed: _togglePasswordVisibility,
        )
            : null,
      ),
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _register,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFC107),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text(
        "Sign Up",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
