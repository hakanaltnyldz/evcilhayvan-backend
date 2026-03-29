import 'package:flutter/material.dart';

/// D8F3DC arka planlı ikon kutusuyla standart ListTile.
/// Settings, preferences ve listelerde tutarlı görünüm sağlar.
class GreenTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBgColor;
  final bool isDestructive;
  final bool showChevron;

  const GreenTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBgColor,
    this.isDestructive = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveIconColor = isDestructive
        ? Colors.red.shade400
        : (iconColor ?? const Color(0xFF2D6A4F));
    final Color effectiveIconBg = isDestructive
        ? Colors.red.shade50
        : (iconBgColor ?? const Color(0xFFD8F3DC));

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: effectiveIconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: effectiveIconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isDestructive ? Colors.red.shade500 : null,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null && showChevron
              ? Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400)
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minLeadingWidth: 40,
    );
  }
}
