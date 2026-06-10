// lib/features/favorites/presentation/widgets/favorite_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/favorites/providers/favorite_providers.dart';

class FavoriteButton extends ConsumerStatefulWidget {
  final String itemType; // 'pet', 'product', 'store'
  final String itemId;
  final Color? color;
  final double size;
  final bool showBackground;

  const FavoriteButton({
    super.key,
    required this.itemType,
    required this.itemId,
    this.color,
    this.size = 24,
    this.showBackground = false,
  });

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load initial favorite state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authProvider) == null) return;
      ref
          .read(favoriteStateProvider.notifier)
          .loadFavoriteState(itemType: widget.itemType, itemId: widget.itemId);
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;
    if (ref.read(authProvider) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favorilere eklemek icin giris yapmalisiniz'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(favoriteStateProvider.notifier)
          .toggleFavorite(itemType: widget.itemType, itemId: widget.itemId);

      if (mounted) {
        final isFavorite = ref
            .read(favoriteStateProvider.notifier)
            .isFavorite(widget.itemType, widget.itemId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite ? 'Favorilere eklendi' : 'Favorilerden kaldırıldı',
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteState = ref.watch(favoriteStateProvider);
    final isFavorite =
        favoriteState['${widget.itemType}:${widget.itemId}'] ?? false;

    final iconWidget = Icon(
      isFavorite ? Icons.favorite : Icons.favorite_border,
      color: isFavorite ? Colors.red : (widget.color ?? Colors.white),
      size: widget.size,
    );

    final button = IconButton(
      onPressed: _isLoading ? null : _toggleFavorite,
      icon: _isLoading
          ? SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  widget.color ?? Colors.white,
                ),
              ),
            )
          : iconWidget,
    );

    if (widget.showBackground) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: button,
      );
    }

    return button;
  }
}
