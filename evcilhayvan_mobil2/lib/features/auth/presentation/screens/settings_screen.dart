// lib/features/auth/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:evcilhayvan_mobil2/core/providers/theme_provider.dart';
import 'package:evcilhayvan_mobil2/core/providers/locale_provider.dart';
import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/core/widgets/green_tile.dart';
import 'package:evcilhayvan_mobil2/core/widgets/section_header.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _notificationsKey = 'settings.notifications_enabled';
  static const _matchAlertsKey = 'settings.match_alerts_enabled';
  static const _autoStartChatKey = 'settings.auto_start_chat';
  static const _compactCardsKey = 'settings.compact_cards';

  SharedPreferences? _prefs;
  bool _isLoadingPrefs = true;
  bool _notificationsEnabled = true;
  bool _matchAlertsEnabled = true;
  bool _autoStartChat = true;
  bool _compactCards = false;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefs = prefs;
      _notificationsEnabled =
          prefs.getBool(_notificationsKey) ?? _notificationsEnabled;
      _matchAlertsEnabled =
          prefs.getBool(_matchAlertsKey) ?? _matchAlertsEnabled;
      _autoStartChat = prefs.getBool(_autoStartChatKey) ?? _autoStartChat;
      _compactCards = prefs.getBool(_compactCardsKey) ?? _compactCards;
      _isLoadingPrefs = false;
    });
  }

  void _updatePreference(String key, bool value, void Function() apply) {
    setState(apply);
    _prefs?.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ModernBackground(
        child: SafeArea(
          child: _isLoadingPrefs
              ? const Center(child: PawLoading())
              : ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _SettingsHeader(userName: user?.name, email: user?.email),
              const SizedBox(height: 20),
              _SettingsCard(
                title: l10n.settingsSectionAccount,
                subtitle: l10n.settingsSectionAccountSub,
                children: [
                  GreenTile(
                    icon: Icons.person_outline,
                    title: l10n.settingsEditProfile,
                    subtitle: l10n.settingsEditProfileSub,
                    onTap: () => context.pushNamed('edit-profile'),
                  ),
                  GreenTile(
                    icon: Icons.lock_reset,
                    title: l10n.settingsChangePassword,
                    subtitle: l10n.settingsChangePasswordSub,
                    onTap: () => context.pushNamed('forgot-password'),
                  ),
                  GreenTile(
                    icon: Icons.shopping_bag_outlined,
                    title: l10n.settingsMyOrders,
                    subtitle: l10n.settingsMyOrdersSub,
                    onTap: () => context.push('/store/orders'),
                  ),
                  GreenTile(
                    icon: Icons.favorite_outline,
                    title: l10n.settingsMyFavorites,
                    subtitle: l10n.settingsMyFavoritesSub,
                    onTap: () => context.pushNamed('favorites'),
                  ),
                  GreenTile(
                    icon: Icons.local_offer_outlined,
                    title: 'Kuponlarım',
                    subtitle: 'İndirim kuponlarınızı görüntüleyin',
                    onTap: () => context.pushNamed('my-coupons'),
                  ),
                  GreenTile(
                    icon: Icons.location_on_outlined,
                    title: 'Adreslerim',
                    subtitle: 'Kayıtlı adreslerinizi yönetin',
                    onTap: () => context.pushNamed('my-addresses'),
                  ),
                ],
              ),
              if (user != null && user.role != 'seller') ...[
                const SizedBox(height: 20),
                _SettingsCard(
                  title: 'Satıcı Ol',
                  subtitle: 'Mağazanızı açın ve ürün satmaya başlayın',
                  children: [
                    GreenTile(
                      icon: Icons.store_outlined,
                      title: 'Satıcı Başvurusu Yap',
                      subtitle: 'Başvurunuzu gönderin, admin onayından sonra mağazanız açılır',
                      onTap: () => context.pushNamed('store-apply'),
                    ),
                    GreenTile(
                      icon: Icons.assignment_outlined,
                      title: 'Başvuru Durumum',
                      subtitle: 'Mevcut başvurunuzun durumunu görüntüleyin',
                      onTap: () => context.pushNamed('application-status'),
                    ),
                  ],
                ),
              ],
              if (user?.role == 'seller') ...[
                const SizedBox(height: 20),
                _SettingsCard(
                  title: l10n.settingsSectionStore,
                  subtitle: l10n.settingsSectionStoreSub,
                  children: [
                    GreenTile(
                      icon: Icons.storefront_outlined,
                      title: l10n.settingsMyStore,
                      subtitle: l10n.settingsMyStoreSub,
                      onTap: () => context.pushNamed('seller-dashboard'),
                    ),
                    GreenTile(
                      icon: Icons.receipt_long_outlined,
                      title: l10n.settingsIncomingOrders,
                      subtitle: l10n.settingsIncomingOrdersSub,
                      onTap: () => context.pushNamed('seller-orders'),
                    ),
                    GreenTile(
                      icon: Icons.inventory_2_outlined,
                      title: l10n.settingsManageProducts,
                      subtitle: l10n.settingsManageProductsSub,
                      onTap: () => context.pushNamed('product-management'),
                    ),
                    GreenTile(
                      icon: Icons.discount_outlined,
                      title: 'Kupon Yönetimi',
                      subtitle: 'Mağazanız için kupon oluşturun',
                      onTap: () => context.pushNamed('seller-coupons'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              _SettingsCard(
                title: l10n.settingsSectionNotif,
                subtitle: l10n.settingsSectionNotifSub,
                children: [
                  GreenTile(
                    icon: Icons.notifications_outlined,
                    title: 'Bildirim Tercihleri',
                    subtitle: 'Hangi bildirimleri alacağını seç',
                    onTap: () => context.pushNamed('notification-preferences'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SettingsCard(
                title: l10n.settingsSectionAppExp,
                subtitle: l10n.settingsSectionAppExpSub,
                children: [
                  SwitchListTile.adaptive(
                    value: _compactCards,
                    title: Text(l10n.settingsCompactCards),
                    subtitle: Text(l10n.settingsCompactCardsSub),
                    onChanged: (value) {
                      _updatePreference(
                        _compactCardsKey,
                        value,
                        () => _compactCards = value,
                      );
                    },
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
                      final l10n = AppLocalizations.of(context)!;
                      return SwitchListTile.adaptive(
                        secondary: const Icon(Icons.dark_mode_outlined),
                        title: Text(l10n.settingsDarkMode),
                        subtitle: Text(l10n.settingsDarkModeSub),
                        value: isDark,
                        onChanged: (_) =>
                            ref.read(themeModeProvider.notifier).toggle(),
                      );
                    },
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final locale = ref.watch(localeProvider);
                      final l10n = AppLocalizations.of(context)!;
                      return GreenTile(
                        icon: Icons.language_outlined,
                        title: l10n.languageLabel,
                        subtitle: l10n.selectLanguage,
                        showChevron: false,
                        trailing: _LanguageSegmentedButton(
                          currentLocale: locale,
                          onChanged: (newLocale) {
                            ref.read(localeProvider.notifier).setLocale(newLocale);
                          },
                        ),
                      );
                    },
                  ),
                  GreenTile(
                    icon: Icons.download_outlined,
                    title: l10n.settingsExportData,
                    subtitle: l10n.settingsExportDataSub,
                    onTap: () => _showSnack(
                      AppLocalizations.of(context)!.settingsExportData,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SettingsCard(
                title: l10n.settingsSectionSupport,
                subtitle: l10n.settingsSectionSupportSub,
                children: [
                  GreenTile(
                    icon: Icons.help_outline,
                    title: l10n.settingsHelp,
                    onTap: () => _showSnack(l10n.settingsHelp),
                  ),
                  GreenTile(
                    icon: Icons.mail_outline,
                    title: l10n.settingsContact,
                    onTap: () => _showSnack('support@evcildostum.app'),
                  ),
                  GreenTile(
                    icon: Icons.share_outlined,
                    title: l10n.settingsShare,
                    subtitle: l10n.settingsShareSub,
                    onTap: () => _showSnack(l10n.settingsShare),
                  ),
                  GreenTile(
                    icon: Icons.star_outline_rounded,
                    title: l10n.settingsReview,
                    subtitle: l10n.reviewDialogDesc,
                    iconColor: const Color(0xFFFFC107),
                    iconBgColor: const Color(0xFFFFF8E1),
                    onTap: () async {
                      final review = InAppReview.instance;
                      if (await review.isAvailable()) {
                        await review.requestReview();
                      } else {
                        await review.openStoreListing(appStoreId: 'com.evcildostum.app');
                      }
                    },
                  ),
                  GreenTile(
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.settingsPrivacy,
                    onTap: () => context.pushNamed('privacy-policy'),
                  ),
                  GreenTile(
                    icon: Icons.report_outlined,
                    title: 'Şikayet Bildir',
                    subtitle: 'Sorun veya şikayetinizi iletin',
                    onTap: () => context.pushNamed('complaint'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SettingsCard(
                title: l10n.settingsLogout,
                subtitle: l10n.profileLogout,
                children: [
                  GreenTile(
                    icon: Icons.logout,
                    title: l10n.logout,
                    isDestructive: true,
                    showChevron: false,
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.goNamed('login');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'v1.0.0 · Topluluğunu sevgiyle büyüt',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final String? userName;
  final String? email;

  const _SettingsHeader({this.userName, this.email});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = (userName?.isNotEmpty ?? false)
        ? userName!.trim()[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.18),
            theme.colorScheme.secondary.withOpacity(0.14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            child: Text(
              initials,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? 'Misafir Kullanıcı',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email ?? 'Henüz bir e-posta eklenmedi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _LanguageSegmentedButton extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onChanged;

  const _LanguageSegmentedButton({
    required this.currentLocale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isTr = currentLocale.languageCode == 'tr';
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LangChip(
          label: '🇹🇷 TR',
          selected: isTr,
          onTap: () => onChanged(const Locale('tr')),
          theme: theme,
        ),
        const SizedBox(width: 6),
        _LangChip(
          label: '🇬🇧 EN',
          selected: !isTr,
          onTap: () => onChanged(const Locale('en')),
          theme: theme,
        ),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SectionHeader(title: title),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}