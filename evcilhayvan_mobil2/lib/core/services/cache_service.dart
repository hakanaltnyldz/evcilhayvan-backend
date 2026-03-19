import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic stale-while-revalidate cache backed by SharedPreferences.
///
/// Usage:
/// ```dart
/// // In AsyncNotifier.build():
/// final data = await CacheService.staleWhileRevalidate<List<Category>>(
///   key: 'cache_categories_v1',
///   ttl: const Duration(hours: 2),
///   fromJson: (raw) => (raw as List).map((e) => Category.fromJson(e)).toList(),
///   toJson: (list) => list.map((e) => e.toJson()).toList(),
///   fetch: () => _repo.categories(),
///   onUpdate: (fresh) => state = AsyncData(fresh),
/// );
/// state = AsyncData(data);
/// ```
class CacheService {
  static const String _tsPrefix = '_ts:';

  // ─── Write ────────────────────────────────────────────────────────────────

  static Future<void> set<T>({
    required String key,
    required T data,
    required dynamic Function(T) toJson,
    Duration ttl = const Duration(hours: 1),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(toJson(data));
    await prefs.setString(key, payload);
    await prefs.setInt(
      '$_tsPrefix$key',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ─── Read (returns null if missing or expired) ─────────────────────────────

  static Future<T?> get<T>({
    required String key,
    required T Function(dynamic) fromJson,
    Duration ttl = const Duration(hours: 1),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    final ts = prefs.getInt('$_tsPrefix$key') ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > ttl.inMilliseconds) return null; // expired
    try {
      return fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  // ─── Stale-while-revalidate ────────────────────────────────────────────────

  /// Returns cached data immediately (possibly stale) and triggers a background
  /// fetch to refresh. Calls [onUpdate] when fresh data arrives.
  ///
  /// If no cache exists, waits for the network fetch and caches the result.
  static Future<T> staleWhileRevalidate<T>({
    required String key,
    required Future<T> Function() fetch,
    required T Function(dynamic) fromJson,
    required dynamic Function(T) toJson,
    required void Function(T fresh) onUpdate,
    Duration ttl = const Duration(hours: 1),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    final ts = prefs.getInt('$_tsPrefix$key') ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    final hasCache = raw != null && raw.isNotEmpty;

    if (hasCache) {
      // Return cached immediately, refresh in background
      T? cached;
      try {
        cached = fromJson(jsonDecode(raw!));
      } catch (_) {}

      if (cached != null) {
        // Revalidate in background (whether stale or not)
        _revalidate<T>(
          key: key,
          fetch: fetch,
          toJson: toJson,
          onUpdate: onUpdate,
        );
        return cached;
      }
    }

    // No usable cache → await network
    final fresh = await fetch();
    await set(key: key, data: fresh, toJson: toJson, ttl: ttl);
    return fresh;
  }

  // ─── Invalidate ───────────────────────────────────────────────────────────

  static Future<void> invalidate(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    await prefs.remove('$_tsPrefix$key');
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  static void _revalidate<T>({
    required String key,
    required Future<T> Function() fetch,
    required dynamic Function(T) toJson,
    required void Function(T fresh) onUpdate,
  }) {
    fetch().then((fresh) async {
      await set(key: key, data: fresh, toJson: toJson);
      onUpdate(fresh);
    }).catchError((_) {
      // Silently ignore revalidation errors — cached data is still shown
    });
  }
}
