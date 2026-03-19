// lib/features/favorites/providers/favorite_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/features/favorites/data/repositories/favorite_repository.dart';
import 'package:evcilhayvan_mobil2/features/favorites/domain/models/favorite_model.dart';

// Repository provider
final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository();
});

// Get all favorites
final favoritesProvider = FutureProvider.autoDispose<List<FavoriteModel>>((ref) async {
  final repo = ref.watch(favoriteRepositoryProvider);
  return repo.getFavorites();
});

// Get favorites by type
final favoritesByTypeProvider = FutureProvider.autoDispose
    .family<List<FavoriteModel>, String>((ref, type) async {
  final repo = ref.watch(favoriteRepositoryProvider);
  return repo.getFavorites(type: type);
});

// Get favorites count
final favoritesCountProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repo = ref.watch(favoriteRepositoryProvider);
  return repo.getFavoritesCount();
});

// Check if specific item is favorited
final isFavoriteProvider = FutureProvider.autoDispose
    .family<bool, FavoriteCheckParams>((ref, params) async {
  final repo = ref.watch(favoriteRepositoryProvider);
  return repo.checkFavorite(
    itemType: params.itemType,
    itemId: params.itemId,
  );
});

// State notifier for managing favorite state
final favoriteStateProvider =
    StateNotifierProvider<FavoriteStateNotifier, Map<String, bool>>((ref) {
  return FavoriteStateNotifier(ref);
});

class FavoriteStateNotifier extends StateNotifier<Map<String, bool>> {
  final Ref ref;

  FavoriteStateNotifier(this.ref) : super({});

  String _getKey(String itemType, String itemId) => '$itemType:$itemId';

  bool isFavorite(String itemType, String itemId) {
    return state[_getKey(itemType, itemId)] ?? false;
  }

  Future<void> toggleFavorite({
    required String itemType,
    required String itemId,
  }) async {
    final key = _getKey(itemType, itemId);
    final currentState = state[key] ?? false;

    // Optimistic update
    state = {...state, key: !currentState};

    try {
      final repo = ref.read(favoriteRepositoryProvider);

      if (!currentState) {
        // Add to favorites
        await repo.addFavorite(itemType: itemType, itemId: itemId);
      } else {
        // Remove from favorites
        await repo.removeFavorite(itemType: itemType, itemId: itemId);
      }

      // Invalidate list providers to refresh
      ref.invalidate(favoritesProvider);
      ref.invalidate(favoritesByTypeProvider);
      ref.invalidate(favoritesCountProvider);
    } catch (e) {
      // Revert on error
      state = {...state, key: currentState};
      rethrow;
    }
  }

  Future<void> loadFavoriteState({
    required String itemType,
    required String itemId,
  }) async {
    final key = _getKey(itemType, itemId);
    try {
      final repo = ref.read(favoriteRepositoryProvider);
      final isFav = await repo.checkFavorite(
        itemType: itemType,
        itemId: itemId,
      );
      state = {...state, key: isFav};
    } catch (_) {
      // Ignore errors when loading state
    }
  }
}

// Helper class for isFavoriteProvider params
class FavoriteCheckParams {
  final String itemType;
  final String itemId;

  FavoriteCheckParams({required this.itemType, required this.itemId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteCheckParams &&
        other.itemType == itemType &&
        other.itemId == itemId;
  }

  @override
  int get hashCode => itemType.hashCode ^ itemId.hashCode;
}
