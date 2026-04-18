import 'package:flutter/material.dart';

class BadgeChip extends StatelessWidget {
  final String badge;

  const BadgeChip({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final config = _badgeConfig(badge);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, color: config.color, size: 14),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _badgeConfig(String badge) {
    switch (badge) {
      case 'newcomer':
        return _BadgeConfig(
          icon: Icons.emoji_events_rounded,
          color: const Color(0xFFCD7F32), // bronze
          label: 'Yeni Üye',
        );
      case 'active':
        return _BadgeConfig(
          icon: Icons.star_rounded,
          color: const Color(0xFF9E9E9E), // silver
          label: 'Aktif',
        );
      case 'veteran':
        return _BadgeConfig(
          icon: Icons.military_tech_rounded,
          color: const Color(0xFFFFB300), // gold
          label: 'Veteran',
        );
      case 'champion':
        return _BadgeConfig(
          icon: Icons.diamond_rounded,
          color: const Color(0xFF00B4D8), // diamond
          label: 'Şampiyon',
        );
      default:
        return _BadgeConfig(
          icon: Icons.workspace_premium_rounded,
          color: Colors.purple,
          label: badge,
        );
    }
  }
}

class _BadgeConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _BadgeConfig({required this.icon, required this.color, required this.label});
}
