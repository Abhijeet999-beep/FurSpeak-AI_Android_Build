import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:furspeak_ai/config/lottie_registry.dart';
import 'package:furspeak_ai/config/app_config.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/theme/app_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

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
      animation: 'onboarding_1',
      title: 'Welcome to FurSpeak AI',
      description:
          'Understand your furry friend\'s emotions with advanced AI technology.',
    ),
    _OnboardingPageData(
      animation: 'onboarding_2',
      title: 'Real-time Emotion Detection',
      description:
          'Capture your dog\'s emotions through photos or videos for instant analysis.',
    ),
    _OnboardingPageData(
      animation: 'onboarding_3',
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
      // Last page — must persist onboarding state before navigating
      _onGetStarted();
    }
  }

  void _onGetStarted() {
    HapticFeedback.mediumImpact();
    if (_dontShowAgain) {
      AppConfig.setShowOnboarding(false);
    }
    context.read<AuthProvider>().completeOnboarding();
  }

  void _onSkip() {
    HapticFeedback.lightImpact();
    context.read<AuthProvider>().completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.warmGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _handlePageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _OnboardingPage(
                        page: _pages[index],
                        isCurrent: _currentPage == index,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    children: [
                      // Page Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: AppTheme.animMedium,
                            curve: Curves.easeOutBack,
                            width: _currentPage == index ? 32 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentPage == index
                                  ? AppTheme.primaryColor
                                  : AppTheme.primaryColor.withOpacity(0.15),
                              boxShadow: _currentPage == index
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Don't show again toggle (Last page only)
                      if (_currentPage == _pages.length - 1)
                        _buildDontShowAgainToggle()
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scale(begin: const Offset(0.9, 0.9)),

                      const SizedBox(height: 16),

                      // Primary Action Button
                      SquishButton(
                        onPressed: _handleNext,
                        child: Container(
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: AppTheme.borderRadiusPill,
                            boxShadow: AppTheme.floatShadow,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _currentPage < _pages.length - 1
                                ? 'Next'
                                : 'Get Started',
                            style: AppTheme.titleStyle.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      // Skip Button
                      AnimatedOpacity(
                        duration: AppTheme.animMedium,
                        opacity: _currentPage < _pages.length - 1 ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: _currentPage >= _pages.length - 1,
                          child: TextButton(
                            onPressed: _onSkip,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Skip',
                              style: AppTheme.bodyStyle.copyWith(
                                color: AppTheme.primaryColor.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildDontShowAgainToggle() {
    return GestureDetector(
      onTap: () {
        setState(() => _dontShowAgain = !_dontShowAgain);
        FurHaptics.select();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _dontShowAgain,
                onChanged: (v) {
                  setState(() => _dontShowAgain = v ?? false);
                  FurHaptics.select();
                },
                activeColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Don\'t show onboarding again',
              style: AppTheme.captionStyle.copyWith(
                color: AppTheme.textLightColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
  final bool isCurrent;
  const _OnboardingPage({required this.page, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Semantics(
            label: page.title,
            child: RepaintBoundary(
              child: Lottie.asset(
                LottieRegistry.get(page.animation),
                width: 280,
                height: 280,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.pets, size: 80, color: AppTheme.primaryColor),
              ),
            )
                .animate(target: isCurrent ? 1 : 0)
                .scale(
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                )
                .fadeIn(duration: 400.ms),
          ),
          const Spacer(),
          Text(
            page.title,
            style: AppTheme.headingStyle.copyWith(
              color: AppTheme.primaryColor,
              fontSize: 28,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          )
              .animate(target: isCurrent ? 1 : 0)
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 20),
          Text(
            page.description,
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.textLightColor,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate(target: isCurrent ? 1 : 0)
              .fadeIn(duration: 400.ms, delay: 400.ms)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
