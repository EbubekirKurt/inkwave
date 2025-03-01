import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkwave/onboarding/onboarding_interests.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  Future<void> completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("first_time", false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingInterestsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ElevatedButton(
          onPressed: () => completeOnboarding(context),
          child: const Text("Devam Et"),
        ),
      ),
    );
  }
}
