// lib/features/search/presentation/global_search_screen.dart
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';

// ── Search History ─────────────────────────────────────────────────────────

class _SearchHistoryRepo {
  static const _key = 'search_history_v1';
  static const _maxItems = 10;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> add(String query) async {
    if (query.trim().length < 2) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.remove(query); // remove duplicate
    list.insert(0, query);
    if (list.length > _maxItems) list.removeLast();
    await prefs.setStringList(_key, list);
  }

  Future<void> remove(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.remove(query);
    await prefs.setStringList(_key, list);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// ── Result Models ──────────────────────────────────────────────────────────

class _SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final _ResultType type;

  const _SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.type,
  });
}

enum _ResultType { pet, store, vet }

// ── Repository ─────────────────────────────────────────────────────────────

class _GlobalSearchRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<_SearchResult>> search(String q) async {
    if (q.trim().length < 2) return [];

    final results = <_SearchResult>[];
    final futures = await Future.wait([
      _searchPets(q),
      _searchStores(q),
      _searchVets(q),
    ], eagerError: false);

    for (final list in futures) {
      results.addAll(list);
    }
    return results;
  }

  Future<List<_SearchResult>> _searchPets(String q) async {
    try {
      final res = await _dio.get('/api/adverts', queryParameters: {'q': q, 'limit': 6});
      final raw = res.data['items'] ?? res.data['pets'] ?? res.data['adverts'] ?? [];
      return (raw as List).map((json) {
        final pet = Pet.fromJson(Map<String, dynamic>.from(json));
        return _SearchResult(
          id: pet.id,
          title: pet.name,
          subtitle: '${pet.species} · ${pet.breed}',
          imageUrl:
              pet.images.isNotEmpty ? pet.images.first : null,
          type: _ResultType.pet,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<_SearchResult>> _searchStores(String q) async {
    try {
      final res = await _dio.get('/api/stores/discover', queryParameters: {'q': q, 'limit': 4});
      final raw = res.data['stores'] ?? [];
      return (raw as List).map<_SearchResult>((json) {
        return _SearchResult(
          id: json['_id'] ?? json['id'] ?? '',
          title: json['name'] ?? '',
          subtitle: json['description'] ?? 'Store',
          imageUrl: json['logo'],
          type: _ResultType.store,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<_SearchResult>> _searchVets(String q) async {
    try {
      final res = await _dio.get('/api/veterinaries', queryParameters: {'q': q, 'limit': 4});
      final raw = res.data['vets'] ?? [];
      return (raw as List).map<_SearchResult>((json) {
        return _SearchResult(
          id: json['_id'] ?? json['id'] ?? '',
          title: json['name'] ?? '',
          subtitle: json['city'] ?? 'Vet',
          imageUrl: json['avatar'],
          type: _ResultType.vet,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final _searchQueryProvider = StateProvider<String>((ref) => '');

final _searchResultsProvider =
    FutureProvider.autoDispose.family<List<_SearchResult>, String>((ref, q) {
  return _GlobalSearchRepository().search(q);
});

// ── Screen ─────────────────────────────────────────────────────────────────

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _ctrl = TextEditingController();
  final _historyRepo = _SearchHistoryRepo();
  String _query = '';
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final h = await _historyRepo.load();
    if (mounted) setState(() => _history = h);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    setState(() => _query = val.trim());
  }

  void _searchTerm(String term) {
    _ctrl.text = term;
    setState(() => _query = term);
  }

  Future<void> _removeHistory(String term) async {
    await _historyRepo.remove(term);
    await _loadHistory();
  }

  Future<void> _clearHistory() async {
    await _historyRepo.clear();
    if (mounted) setState(() => _history = []);
  }

  Future<void> _navigate(_SearchResult result) async {
    await _historyRepo.add(_query);
    await _loadHistory();
    if (!mounted) return;
    switch (result.type) {
      case _ResultType.pet:
        context.pushNamed('pet-detail', pathParameters: {'id': result.id});
        break;
      case _ResultType.store:
        context.pushNamed('store-detail', pathParameters: {'storeId': result.id});
        break;
      case _ResultType.vet:
        context.pushNamed('vet-detail', pathParameters: {'id': result.id});
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: _onChanged,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchHint,
            hintStyle: const TextStyle(color: Colors.white60),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _query.length < 2
          ? _buildEmptyState(theme)
          : _buildResults(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: Color(0xFFD8F3DC), shape: BoxShape.circle),
              child: const Icon(Icons.search_rounded, size: 48, color: Color(0xFF2D6A4F)),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.searchTypeHint,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.searchTypeHintSub,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Geçmiş aramalar
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.searchHistory,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: _clearHistory,
                child: Text(AppLocalizations.of(context)!.searchClearHistory,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _history.map((term) {
              return InputChip(
                avatar: const Icon(Icons.history, size: 16),
                label: Text(term, maxLines: 1),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => _removeHistory(term),
                onPressed: () => _searchTerm(term),
                backgroundColor: const Color(0xFFD8F3DC),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final resultsAsync = ref.watch(_searchResultsProvider(_query));

    return resultsAsync.when(
      loading: () => const Center(child: PawLoading()),
      error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.searchError(e.toString()))),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: Color(0xFFD8F3DC), shape: BoxShape.circle),
                  child: const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF2D6A4F)),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.searchNoResults(_query),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        // Group by type
        final pets = results.where((r) => r.type == _ResultType.pet).toList();
        final stores = results.where((r) => r.type == _ResultType.store).toList();
        final vets = results.where((r) => r.type == _ResultType.vet).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (pets.isNotEmpty) ...[
              _SectionHeader(label: AppLocalizations.of(context)!.searchSectionListings, icon: Icons.pets),
              ...pets.map((r) => _ResultTile(result: r, onTap: () => _navigate(r).ignore())),
            ],
            if (stores.isNotEmpty) ...[
              _SectionHeader(label: AppLocalizations.of(context)!.searchSectionStores, icon: Icons.storefront_outlined),
              ...stores.map((r) => _ResultTile(result: r, onTap: () => _navigate(r).ignore())),
            ],
            if (vets.isNotEmpty) ...[
              _SectionHeader(label: AppLocalizations.of(context)!.searchSectionVets, icon: Icons.local_hospital_outlined),
              ...vets.map((r) => _ResultTile(result: r, onTap: () => _navigate(r).ignore())),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2D6A4F)),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF2D6A4F),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final _SearchResult result;
  final VoidCallback onTap;

  const _ResultTile({required this.result, required this.onTap});

  IconData get _typeIcon {
    switch (result.type) {
      case _ResultType.pet:
        return Icons.pets;
      case _ResultType.store:
        return Icons.storefront_outlined;
      case _ResultType.vet:
        return Icons.local_hospital_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: result.imageUrl != null
            ? Image.network(
                result.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
      title: Text(
        result.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        result.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(_typeIcon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 48,
      height: 48,
      color: const Color(0xFF2D6A4F).withOpacity(0.1),
      child: Icon(_typeIcon, color: const Color(0xFF2D6A4F), size: 24),
    );
  }
}
