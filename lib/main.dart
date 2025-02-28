import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkwave/constants.dart';
import 'package:inkwave/screens/home_screen.dart';
import 'package:inkwave/screens/library_screen.dart';
import 'package:inkwave/screens/profile_screen.dart';
import 'package:inkwave/screens/search_screen.dart';
import 'package:inkwave/screens/book_detail_screen.dart';
import 'package:inkwave/screens/translate_screen.dart';
import 'package:inkwave/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstTime = prefs.getBool("first_time") ?? true;

  runApp(MyApp(isFirstTime: isFirstTime));
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;

  const MyApp({Key? key, required this.isFirstTime}) : super(key: key);

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
      home: isFirstTime ? const OnboardingScreen() : const MainScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/bookDetail': (context) => const BookDetailScreen(),
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
      HomeScreen(),                                      // Ana Sayfa
      TranslateScreen(),                                 // Çeviri Ekranı
      SearchScreen(),                                    // Arama
      LibraryScreen(bookIndexes: libraryBookIndexes),    // Kitaplığım
      ProfileScreen(),                                   // Profilim
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
        type: BottomNavigationBarType.fixed,  // ALT ÇUBUĞUN SABİT KALMASINI SAĞLAR
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.translate), label: 'Çeviri'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Arama'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Kitaplığım'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilim'),
        ],
      ),
    );
  }
}

