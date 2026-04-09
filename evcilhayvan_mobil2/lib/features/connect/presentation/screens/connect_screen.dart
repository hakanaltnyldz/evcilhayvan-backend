import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.connectTitle),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FeatureTile(
            icon: Icons.dynamic_feed_rounded,
            title: l10n.connectSocialFeed,
            subtitle: l10n.connectSocialFeedSub,
            color: const Color(0xFF2D6A4F),
            onTap: () => context.pushNamed('feed'),
          ),
          const SizedBox(height: 12),
          _FeatureTile(
            icon: Icons.search_rounded,
            title: l10n.connectSearch,
            subtitle: l10n.connectSearchSub,
            color: const Color(0xFF40916C),
            onTap: () => context.pushNamed('search'),
          ),
          const SizedBox(height: 12),
          _FeatureTile(
            icon: Icons.map_rounded,
            title: l10n.connectMapDiscover,
            subtitle: l10n.connectMapDiscoverSub,
            color: const Color(0xFF52B788),
            onTap: () => context.pushNamed('map'),
          ),
          const SizedBox(height: 12),
          _FeatureTile(
            icon: Icons.favorite_rounded,
            title: l10n.connectFavorites,
            subtitle: l10n.connectFavoritesSub,
            color: Colors.red,
            onTap: () => context.pushNamed('favorites'),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFD8F3DC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
