import 'package:flutter/material.dart';

class TermsOfServicesScreen extends StatelessWidget {
  const TermsOfServicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090617),
        title: const Text("Kullanım Şartları"),
      ),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            '''
Inkwave Kullanım Şartları

1. Hizmeti kullanarak bu şartları kabul etmiş olursunuz.
2. Kullanıcı verileri gizlilikle korunur.
3. İçeriklerin kopyalanması ve izinsiz paylaşımı yasaktır.
4. Uygulama geliştiricileri, hizmette değişiklik yapma hakkını saklı tutar.

...

Detaylı bilgi için destek ekibimizle iletişime geçebilirsiniz.
''',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
