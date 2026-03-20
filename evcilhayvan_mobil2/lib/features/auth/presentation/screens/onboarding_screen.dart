// lib/features/auth/presentation/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evcilhayvan_mobil2/core/providers/onboarding_provider.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

List<_OnboardingPage> _getPages(AppLocalizations l10n) => [
  _OnboardingPage(
    icon: Icons.pets,
    title: l10n.onboardingPage1Title,
    subtitle: l10n.onboardingPage1Subtitle,
    gradient: const [Color(0xFF6C63FF), Color(0xFF8F7DFF)],
  ),
  _OnboardingPage(
    icon: Icons.favorite_rounded,
    title: l10n.onboardingPage2Title,
    subtitle: l10n.onboardingPage2Subtitle,
    gradient: const [Color(0xFFFF7A59), Color(0xFFFF9F7F)],
  ),
  _OnboardingPage(
    icon: Icons.local_hospital_rounded,
    title: l10n.onboardingPage3Title,
    subtitle: l10n.onboardingPage3Subtitle,
    gradient: const [Color(0xFF2BB673), Color(0xFF54D99F)],
  ),
  _OnboardingPage(
    icon: Icons.storefront_rounded,
    title: l10n.onboardingPage4Title,
    subtitle: l10n.onboardingPage4Subtitle,
    gradient: const [Color(0xFF7C7BFF), Color(0xFF5FD9C1)],
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  late List<_OnboardingPage> _pages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages = _getPages(AppLocalizations.of(context)!);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await markOnboardingSeen();
    ref.read(onboardingSeenProvider.notifier).state = true;
    if (mounted) context.goNamed('login');
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, index) =>
                _OnboardingPageWidget(page: _pages[index]),
          ),

          // Skip button (top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: TextButton(
              onPressed: _finish,
              child: Text(
                AppLocalizations.of(context)!.onboardingSkip,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentPage ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _currentPage
                            ? Colors.white
                            : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Next / Start button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _pages[_currentPage].gradient[0],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black38,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? AppLocalizations.of(context)!.onboardingStart
                            : AppLocalizations.of(context)!.onboardingNext,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
    );
  }
}

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: page.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Animated icon container
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    page.icon,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }
}
