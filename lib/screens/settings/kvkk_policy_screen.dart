import 'package:flutter/material.dart';
import 'package:inkwave/constants.dart';

class KvkkPolicyScreen extends StatelessWidget {
  const KvkkPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text("KVKK Politikası", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            "KVKK kapsamında kişisel verileriniz, yalnızca uygulama işlevselliği ve kullanıcı deneyimini geliştirmek amacıyla saklanır. "
                "Verileriniz üçüncü taraflarla paylaşılmaz. Verilerinizi istediğiniz zaman silebilir veya düzenleyebilirsiniz.",
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}
