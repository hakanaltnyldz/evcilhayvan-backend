// lib/features/auth/presentation/screens/theme_selection_screen.dart
//
// İlk açılışta kullanıcıya Açık / Koyu tema seçimi yaptıran ekran.
// Seçim SharedPrefs'e kaydedilir; sonraki açılışlarda bu ekran gösterilmez.
// Değiştirmek için: Ayarlar → Tema

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/providers/onboarding_provider.dart';
import 'package:evcilhayvan_mobil2/core/providers/theme_provider.dart';

import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

class ThemeSelectionScreen extends ConsumerStatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  ConsumerState<ThemeSelectionScreen> createState() =>
      _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends ConsumerState<ThemeSelectionScreen> {
  ThemeMode? _selected;
  bool _confirming = false;

  Future<void> _confirm() async {
    if (_selected == null || _confirming) return;
    setState(() => _confirming = true);

    await ref.read(themeModeProvider.notifier).setMode(_selected!);
    await markThemeSelected();
    ref.read(themeSelectedProvider.notifier).state = true;

    if (!mounted) return;
    final onboardingSeen = ref.read(onboardingSeenProvider);
    if (onboardingSeen) {
      context.go('/');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 36),

              // ── Başlık ──────────────────────────────────────────────
              Text(
                l10n.themeSelectTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

              const SizedBox(height: 8),

              Text(
                l10n.themeSelectSub,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 36),

              // ── Önizleme kartları ────────────────────────────────────
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(width: 20),
                    Expanded(
                      child: _ThemeCard(
                        mode: ThemeMode.light,
                        label: l10n.themeSelectLight,
                        isSelected: _selected == ThemeMode.light,
                        onTap: () => setState(() => _selected = ThemeMode.light),
                      ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.15),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ThemeCard(
                        mode: ThemeMode.dark,
                        label: l10n.themeSelectDark,
                        isSelected: _selected == ThemeMode.dark,
                        onTap: () => setState(() => _selected = ThemeMode.dark),
                      ).animate(delay: 400.ms).fadeIn().slideX(begin: 0.15),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Devam butonu ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimatedOpacity(
                  opacity: _selected != null ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 250),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _selected != null ? _confirm : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF52B788),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _confirming
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              l10n.themeSelectConfirm,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.3),
              ),

              const SizedBox(height: 28),

              Text(
                l10n.themeSelectChangeHint,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12,
                ),
              ).animate(delay: 600.ms).fadeIn(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone mockup widget
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.mode,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  bool get _isDark => mode == ThemeMode.dark;

  // Light palette
  static const _lightBg = Color(0xFFF4FAF6);
  static const _lightCard = Colors.white;
  static const _lightText = Color(0xFF1B4332);
  static const _lightSub = Color(0xFF52B788);
  static const _lightDivider = Color(0xFFD8F3DC);

  // Dark palette
  static const _darkBg = Color(0xFF121212);
  static const _darkCard = Color(0xFF1E2E28);
  static const _darkText = Colors.white;
  static const _darkSub = Color(0xFF95D5B2);
  static const _darkDivider = Color(0xFF2D4A3E);

  Color get bg => _isDark ? _darkBg : _lightBg;
  Color get card => _isDark ? _darkCard : _lightCard;
  Color get txt => _isDark ? _darkText : _lightText;
  Color get sub => _isDark ? _darkSub : _lightSub;
  Color get divider => _isDark ? _darkDivider : _lightDivider;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              // ── Mockup telefon içeriği ───────────────────────────────
              Expanded(
                child: Container(
                  color: bg,
                  child: Column(
                    children: [
                      // Status bar
                      Container(
                        height: 22,
                        color: _isDark
                            ? const Color(0xFF0D2B1E)
                            : const Color(0xFFD8F3DC),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.wifi, size: 10, color: sub),
                            const SizedBox(width: 3),
                            Icon(Icons.battery_full, size: 10, color: sub),
                            const SizedBox(width: 6),
                          ],
                        ),
                      ),

                      // App bar
                      Container(
                        height: 36,
                        color: card,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D6A4F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.pets,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 50,
                              height: 7,
                              decoration: BoxDecoration(
                                color: txt.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 14,
                              color: sub,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Greeting card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    width: 28,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.pets,
                                  color: Colors.white70, size: 18),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Cards row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            _miniCard(card, txt, sub, Icons.favorite_border, 'İlan'),
                            const SizedBox(width: 6),
                            _miniCard(card, txt, sub, Icons.pets, 'Hayvan'),
                            const SizedBox(width: 6),
                            _miniCard(card, txt, sub, Icons.store, 'Market'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // List items
                      ...List.generate(
                        3,
                        (i) => Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: divider,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2D6A4F).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(Icons.pets,
                                      color: const Color(0xFF2D6A4F), size: 10),
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40 + i * 10.0,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: txt.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      width: 25.0,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: sub.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom nav mockup ────────────────────────────────────
              Container(
                height: 36,
                color: card,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _navIcon(Icons.home_rounded, const Color(0xFF2D6A4F), active: true),
                    _navIcon(Icons.chat_bubble_outline_rounded, sub),
                    _navIcon(Icons.pets_rounded, sub),
                    _navIcon(Icons.store_outlined, sub),
                    _navIcon(Icons.person_outline_rounded, sub),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniCard(Color card, Color txt, Color sub, IconData icon, String label) {
    return Expanded(
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDark ? 0.3 : 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF2D6A4F), size: 14),
            const SizedBox(height: 2),
            Container(
              width: 20,
              height: 4,
              decoration: BoxDecoration(
                color: sub.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, Color color, {bool active = false}) {
    return Container(
      width: 30,
      height: 30,
      decoration: active
          ? BoxDecoration(
              color: const Color(0xFF2D6A4F).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Icon(icon, color: color, size: 14),
    );
  }
}
