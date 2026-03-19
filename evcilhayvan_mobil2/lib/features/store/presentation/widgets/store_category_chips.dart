import 'package:flutter/material.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/category_model.dart';

const List<Color> _chipGradient = [
  Color(0xFF2F1BFF),
  Color(0xFFFF5A7A),
];

/// Yatay kaydırılabilir kategori çipleri.
class StoreCategoryChips extends StatelessWidget {
  const StoreCategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _StoreChip(
          label: 'Tümü',
          icon: Icons.apps_rounded,
          color: AppPalette.storePrimary,
          selected: selectedCategoryId == null,
          onSelected: () => onSelected(null),
        ),
      ),
      ...categories.map(
        (c) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _StoreChip(
            label: c.name,
            icon: c.iconData,
            color: c.colorValue,
            selected: selectedCategoryId == c.id,
            onSelected: () => onSelected(c.id),
          ),
        ),
      ),
    ];

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: chips,
      ),
    );
  }
}

class _StoreChip extends StatelessWidget {
  const _StoreChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: selected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(selected ? 0.35 : 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : AppPalette.onBackground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
