import 'package:flutter/material.dart' as flutter;
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../screens/home_screen.dart';
import 'login/register.dart';
import 'login/forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late RiveAnimationController _controller;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isPasswordVisible = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Varsayılan animasyon başlatılır
    _controller = SimpleAnimation("idle");
  }

  void _togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
      // Şifre göster/gizle butonuna basıldığında animasyon değişebilir
      _controller = SimpleAnimation(isPasswordVisible ? "hands_down" : "hands_up");
    });
  }

  Future<void> _signIn() async {
    setState(() {
      errorMessage = '';
    });

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        errorMessage = "Email ve şifre boş bırakılamaz!";
      });
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        // Firestore üzerinde kullanıcı kaydı yoksa ekle, varsa "last_login" güncelle
        await _checkAndSaveUser(user);

        // Giriş başarılı olunca HomeScreen'e yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = _handleFirebaseError(e.code);
      });
    } catch (e) {
      setState(() {
        errorMessage = "Beklenmeyen bir hata oluştu: $e";
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Eski oturumu temizle
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return; // Kullanıcı iptal ettiyse işlemi durdur.
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Firestore'a kaydet
        await _checkAndSaveUser(user);

        if (!mounted) return;

        // Giriş başarılı, HomeScreen'e yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Google ile giriş yapılamadı: ${e.message}";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Bilinmeyen hata: $e";
      });
    }
  }

  Future<void> _checkAndSaveUser(User user) async {
    try {
      print("📝 Firestore'da kullanıcı olup olmadığını kontrol ediyorum: ${user.uid}");

      DocumentReference userRef = _firestore.collection('users').doc(user.uid);
      DocumentSnapshot userDoc = await userRef.get();

      if (!userDoc.exists) {
        print("🆕 Kullanıcı yeni, Firestore'a kaydediliyor...");
        await userRef.set({
          "uid": user.uid,
          "name": user.displayName ?? "Unknown",
          "email": user.email ?? "",
          "phone_number": user.phoneNumber ?? "",
          "created_at": FieldValue.serverTimestamp(),
          "birthday": "",
          "nationality": "",
          "preferred_language": "English",
          "total_book_count": 0,
          "weekly_book_count": 0,
          "leaderboard_score": 0.0,
          "user_type_id": "/user_types/96LYlKLni2rMImmRLh1k",
        });
        print("✅ Kullanıcı Firestore'a başarıyla kaydedildi.");
      } else {
        print("📌 Kullanıcı zaten var, 'last_login' güncelleniyor...");
        await userRef.update({
          "last_login": FieldValue.serverTimestamp(),
        });
        print("🔄 Kullanıcı giriş yaptı, last_login güncellendi.");
      }
    } catch (e) {
      print("❌ Firestore'a kaydetme hatası: $e");
    }
  }

  String _handleFirebaseError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return "Bu e-postayla eşleşen bir kullanıcı bulunamadı.";
      case 'wrong-password':
        return "Şifre yanlış.";
      case 'invalid-email':
        return "E-posta formatı geçersiz.";
      case 'too-many-requests':
        return "Çok fazla deneme yapıldı, lütfen daha sonra tekrar deneyin.";
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
          // Ayıcık animasyonunun bulunduğu kısım
          SizedBox(
            height: 250,
            child: RiveAnimation.asset(
              "assets/rivs/teddy.riv",
              fit: BoxFit.contain,
              controllers: [_controller],
            ),
          ),
          // Form bölümü
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                _buildTextField(
                  emailController,
                  "Email",
                  Icons.email,
                  false,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  passwordController,
                  "Password",
                  Icons.lock,
                  true,
                ),
                const SizedBox(height: 10),
                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 20),
                _buildSignInButton(),
                const SizedBox(height: 15),
                _buildGoogleSignInButton(),
                _buildForgotPasswordButton(),
                _buildSignUpRedirect(),
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
      bool isObscureField,
      ) {
    return TextField(
      controller: controller,
      obscureText: isObscureField ? !isPasswordVisible : false,
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
        suffixIcon: isObscureField
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

  Widget _buildSignInButton() {
    return ElevatedButton(
      onPressed: _signIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFC107),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text(
        "Sign In",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return ElevatedButton(
      onPressed: _signInWithGoogle,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text(
        "Sign In with Google",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
        );
      },
      child: const Text(
        "Forgot Password?",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildSignUpRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(color: Colors.grey),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegisterScreen()),
            );
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(
              color: Color(0xFFFFC107),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
