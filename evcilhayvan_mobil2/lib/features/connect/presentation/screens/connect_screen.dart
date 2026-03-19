import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşfet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppPalette.backgroundGradient,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _FeatureTile(
              icon: Icons.dynamic_feed_rounded,
              title: 'Sosyal Akış',
              subtitle: 'Evcil hayvan sahiplerini takip et',
              color: AppPalette.primary,
              onTap: () => context.pushNamed('feed'),
            ),
            const SizedBox(height: 12),
            _FeatureTile(
              icon: Icons.search_rounded,
              title: 'Ara',
              subtitle: 'Evcil hayvan, mağaza ve veteriner bul',
              color: AppPalette.secondary,
              onTap: () => context.pushNamed('search'),
            ),
            const SizedBox(height: 12),
            _FeatureTile(
              icon: Icons.map_rounded,
              title: 'Haritada Keşfet',
              subtitle: 'Yakınındaki ilanları haritada gör',
              color: AppPalette.tertiary,
              onTap: () => context.pushNamed('map'),
            ),
            const SizedBox(height: 12),
            _FeatureTile(
              icon: Icons.favorite_rounded,
              title: 'Favoriler',
              subtitle: 'Kaydettiğin ilanlar',
              color: Colors.red,
              onTap: () => context.pushNamed('favorites'),
            ),
          ],
        ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppPalette.onSurfaceVariant)),
        trailing: const Icon(Icons.chevron_right, color: AppPalette.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
