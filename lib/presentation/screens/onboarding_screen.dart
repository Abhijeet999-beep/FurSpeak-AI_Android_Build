import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:furspeak_ai/config/app_config.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/widgets/root_nav_shell.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showSkip = false;
  bool _dontShowAgain = false;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      animation: 'assets/animations/onboarding_1.json',
      title: 'Welcome to FurSpeak AI',
      description:
          'Understand your furry friend\'s emotions with advanced AI technology.',
    ),
    _OnboardingPageData(
      animation: 'assets/animations/onboarding_2.json',
      title: 'Real-time Emotion Detection',
      description:
          'Capture your dog\'s emotions through photos or videos for instant analysis.',
    ),
    _OnboardingPageData(
      animation: 'assets/animations/onboarding_3.json',
      title: 'Track Emotional History',
      description:
          'Keep a record of your dog\'s emotional patterns and track their well-being over time.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Show skip for returning users
    AppConfig.getShowOnboarding().then((show) {
      if (!show) {
        setState(() => _showSkip = true);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _handleNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _onGetStarted() {
    HapticFeedback.mediumImpact();
    if (_dontShowAgain) {
      AppConfig.setShowOnboarding(false);
    }
    context.goLogin();
  }

  void _onSkip() {
    HapticFeedback.lightImpact();
    context.goLogin();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _handlePageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPage(page: _pages[index]);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Page Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? AppTheme.primaryColor
                                : AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handleNext,
                        style: AppTheme.primaryButtonStyle,
                        child: Text(
                          _currentPage < _pages.length - 1
                              ? 'Next'
                              : 'Get Started',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Skip Button
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: _onSkip,
                        child: Text(
                          'Skip',
                          style: AppTheme.titleStyle.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String animation;
  final String title;
  final String description;
  const _OnboardingPageData({
    required this.animation,
    required this.title,
    required this.description,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData page;
  const _OnboardingPage({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: page.title,
            child: Lottie.asset(
              page.animation,
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: AppTheme.subheadingStyle.copyWith(
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.textLightColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
