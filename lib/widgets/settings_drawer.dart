import 'dart:ui';
import 'package:flutter/material.dart';

class SettingsDrawer extends StatelessWidget {
  final VoidCallback onLogout;

  const SettingsDrawer({Key? key, required this.onLogout}) : super(key: key);

  static void show(BuildContext context, VoidCallback onLogout) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Ayarlar",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerRight,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
                ),
                child: const SafeArea(
                  child: SettingsDrawerContent(),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder(); // Bu çağrılmayacak
  }
}

class SettingsDrawerContent extends StatelessWidget {
  const SettingsDrawerContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Geri alma için context üzerinden eriş
    final onLogout = (ModalRoute.of(context)?.settings.arguments as Map?)?['onLogout'] as VoidCallback?;

    return SingleChildScrollView( // ✅ Scroll overflow sorunu çözülüyor
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text("Ayarlar", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text("Şifreyi Yenile"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text("KVKK Politikası"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Uygulama Hakkında"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text("Geri Bildirim Gönder"),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 40),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Çıkış Yap", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              onLogout?.call();
            },
          ),
        ],
      ),
    );
  }
}
