import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inkwave/constants.dart';
import 'package:inkwave/screens/home_screen.dart';
import 'package:inkwave/screens/library_screen.dart';
import 'package:inkwave/screens/profile/profile_screen.dart';
import 'package:inkwave/screens/search_screen.dart';
import 'package:inkwave/screens/book_detail_screen.dart';
import 'package:inkwave/screens/translate_screen.dart';
import 'package:inkwave/screens/login.dart';
import 'package:inkwave/screens/social/social.dart';
import 'package:inkwave/screens/settings/add_interest.dart';
import 'package:inkwave/screens/settings/time_spent_screen.dart';
import 'package:inkwave/onboarding/onboarding_screen.dart';
import 'package:inkwave/onboarding/onboarding_interests.dart';
import 'package:inkwave/onboarding/onboarding_finish.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isFirstTime = true;
  bool _isProfileCompleted = false;
  bool _isInterestSelected = false;
  DateTime? _sessionStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAppState();
    _sessionStart = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initializeAppState() async {
    final prefs = await SharedPreferences.getInstance();
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};

    _isFirstTime = prefs.getBool("first_time") ?? true;

    if (data['name'] != null && data['surname'] != null && data['phone_number'] != null) {
      _isProfileCompleted = true;
      await prefs.setBool("profile_completed", true);
    }

    if (data['interest'] != null && (data['interest'] as List).isNotEmpty) {
      _isInterestSelected = true;
      await prefs.setBool("interest_selected", true);
    }

    setState(() => _isLoading = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (_sessionStart != null) {
        final duration = DateTime.now().difference(_sessionStart!);
        _updateTimeSpent(duration);
      }
    } else if (state == AppLifecycleState.resumed) {
      _sessionStart = DateTime.now();
    }
  }

  Future<void> _updateTimeSpent(Duration duration) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final key = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    final data = snapshot.data() ?? {};

    int total = data['time_spent'] ?? 0;
    final logs = Map<String, dynamic>.from(data['time_logs'] ?? {});

    total += duration.inSeconds;
    logs[key] = (logs[key] ?? 0) + duration.inSeconds;

    await docRef.set({'time_spent': total, 'time_logs': logs}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inkwave',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppConstants.primaryColor,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppConstants.primaryColor,
          secondary: AppConstants.accentColor,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (!snapshot.hasData) {
            return const LoginScreen();
          }

          if (_isFirstTime) return const OnboardingScreen();
          if (!_isInterestSelected) return const OnboardingInterestsScreen();
          if (!_isProfileCompleted) return const OnboardingFinishScreen();
          return const MainScreen();
        },
      ),
      routes: {
        '/home': (context) => const MainScreen(),
        '/bookDetail': (context) => const BookDetailScreen(),
        '/search': (context) => const SearchScreen(),
        '/add-interests': (context) => const AddInterestsScreen(),
        '/time-spent': (context) => const TimeSpentScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    TranslateScreen(),
    SocialPage(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppConstants.accentColor,
        unselectedItemColor: Colors.white54,
        backgroundColor: AppConstants.primaryColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.translate), label: 'Çeviri'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Sosyal'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Kitaplığım'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilim'),
        ],
      ),
    );
  }
}

