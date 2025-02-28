class OnboardingContent {
  final String title;
  final String description;
  final String image;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.image,
  });
}

List<OnboardingContent> onboardingData = [
  OnboardingContent(
    title: "Hoş Geldiniz!",
    description: "Inkwave ile kitapları keşfetmeye hazır mısınız?",
    image: "assets/onboarding/welcome.png",
  ),
  OnboardingContent(
    title: "Kendi Kütüphanenizi Oluşturun",
    description: "Sevdiğiniz kitapları kaydedin ve istediğiniz zaman ulaşın.",
    image: "assets/onboarding/library.png",
  ),
  OnboardingContent(
    title: "Kitapları Çevirin ve Okuyun",
    description: "Daha fazla kaynağa erişmek için metinleri çevirebilirsiniz.",
    image: "assets/onboarding/translate.png",
  ),
];
