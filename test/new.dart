import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:inkwave/main.dart';

Future<void> testFirestoreAccess() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (doc.exists) {
        print("Firestore Access Success ✅: ${doc.data()}");
      } else {
        print("Firestore Access Failed ❌: Document not found");
      }
    } else {
      print("User is not logged in ❌");
    }
  } catch (e) {
    print("Firestore Permission Error ❌: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  testFirestoreAccess();
  runApp(const MyApp());
}
