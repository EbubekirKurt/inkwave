import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/screens/home_screen.dart';
import 'package:inkwave/screens/library_screen.dart';
import 'package:inkwave/screens/profile/profile_screen.dart';
import 'package:inkwave/screens/search_screen.dart';
import 'package:inkwave/screens/book_detail_screen.dart';
import 'package:inkwave/screens/translate_screen.dart';
import 'package:inkwave/onboarding/onboarding_screen.dart';
import 'package:inkwave/onboarding/onboarding_interests.dart';
import 'package:inkwave/onboarding/onboarding_finish.dart';
import 'package:inkwave/screens/login.dart';
import 'package:inkwave/screens/social/social.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isFirstTime = true;
  bool _isProfileCompleted = false;
  bool _isInterestSelected = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserData();
  }

  Future<void> _checkUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Kullanıcı giriş yaptı mı kontrol et
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (prefs.getBool("first_time") == null) {
      await prefs.setBool("first_time", true);
      await prefs.setBool("interest_selected", false);
      await prefs.setBool("profile_completed", false);
    }

    _isFirstTime = prefs.getBool("first_time") ?? true;
    _isInterestSelected = prefs.getBool("interest_selected") ?? false;
    _isProfileCompleted = prefs.getBool("profile_completed") ?? false;

    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        if (userData.containsKey("name") &&
            userData.containsKey("surname") &&
            userData.containsKey("phone_number")) {
          _isProfileCompleted = true;
          prefs.setBool("profile_completed", true);
        }

        if (userData.containsKey("interest")) {
          _isInterestSelected = true;
          prefs.setBool("interest_selected", true);
        }
      }
    } catch (e) {
      print("Firestore veri okuma hatası: $e");
    }

    setState(() {
      _isLoading = false;
    });
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
          if (snapshot.hasData) {
            if (_isFirstTime) {
              return const OnboardingScreen();
            } else if (!_isInterestSelected) {
              return const OnboardingInterestsScreen();
            } else if (!_isProfileCompleted) {
              return const OnboardingFinishScreen();
            } else {
              return const MainScreen();
            }
          } else {
            return const LoginScreen();
          }
        },
      ),
      routes: {
        '/home': (context) => const MainScreen(),
        '/bookDetail': (context) => const BookDetailScreen(),
        '/search': (context) => const SearchScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<int> libraryBookIndexes = [];

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),
      const TranslateScreen(),
      const SearchScreen(),
      const SocialPage(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
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
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Arama'),
          BottomNavigationBarItem(icon: Icon(Icons.social_distance), label: 'Sosyal'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilim'),
        ],
      ),
    );
  }
}
