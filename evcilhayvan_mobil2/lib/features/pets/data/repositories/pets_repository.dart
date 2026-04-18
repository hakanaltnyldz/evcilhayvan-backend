// lib/features/pets/data/repositories/pets_repository.dart

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/services/cache_service.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';

class LikeResult {
  final bool didMatch;
  final PetOwner? matchedUser;
  LikeResult({required this.didMatch, this.matchedUser});
}

final petsRepositoryProvider = Provider<PetsRepository>((ref) {
  final client = ApiClient();
  return PetsRepository(client);
});

class PetsRepository {
  PetsRepository(this._client);
  final ApiClient _client;
  Dio get _dio => _client.dio;
  static const _feedCacheKey = 'cache_pet_feed';
  static const _storeProductsCacheKey = 'cache_store_products';

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    } catch (e) {
      throw ApiError(e.toString());
    }
  }

  Future<List<Pet>> _readCachedPets(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((json) => Pet.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<void> _writeCachedPets(String key, List<Pet> pets) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = jsonEncode(pets.map((p) => p.toJson()).toList());
    await prefs.setString(key, serialized);
  }

  Future<List<Pet>> getCachedFeed() => _readCachedPets(_feedCacheKey);

  Future<void> cacheFeed(List<Pet> pets) =>
      _writeCachedPets(_feedCacheKey, pets);

  Future<List<Pet>> getPetFeed() {
    return _guard(() async {
      final response = await _dio.get('/api/pets/feed');
      final List<dynamic> petListJson =
          (response.data['items'] ?? []) as List<dynamic>;
      return petListJson.map((json) => Pet.fromJson(json)).toList();
    });
  }

  Future<List<Pet>> getPets({String? advertType}) {
    return _guard(() async {
      final response = await _dio.get(
        '/api/adverts',
        queryParameters: {if (advertType != null) 'type': advertType},
      );
      final List<dynamic> petListJson =
          response.data['items'] ?? response.data['pets'] ?? [];
      return petListJson.map((json) => Pet.fromJson(json)).toList();
    });
  }

  Future<List<Pet>> getMyPets() {
    return _guard(() async {
      final response = await _dio.get('/api/pets/me');
      final List<dynamic> petListJson = response.data['pets'];
      return petListJson.map((json) => Pet.fromJson(json)).toList();
    });
  }

  Future<List<Pet>> getMyAdverts({String? advertType}) {
    return _guard(() async {
      final response = await _dio.get(
        '/api/adverts/me',
        queryParameters: {if (advertType != null) 'type': advertType},
      );
      final data =
          response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      final List<dynamic> petListJson =
          (data['result'] as List?) ??
          (data['pets'] as List?) ??
          (data['items'] as List?) ??
          (data['data'] as List?) ??
          const [];
      return petListJson.map((json) => Pet.fromJson(json)).toList();
    });
  }

  Future<List<Pet>> getAdoptionAdverts() => getPets(advertType: 'adoption');

  Future<List<Pet>> getMatingAdverts() => getPets(advertType: 'mating');

  Future<({List<Pet> items, bool hasMore})> getPetsPaginated({
    String? advertType,
    int page = 1,
    int limit = 10,
    double? lat,
    double? lng,
    double? radiusKm,
    String? species,
    String? gender,
    bool? vaccinated,
    String? breed,
    String? startsWith,
    int? minAgeMonths,
    int? maxAgeMonths,
  }) {
    return _guard(() async {
      final response = await _dio.get(
        '/api/adverts',
        queryParameters: {
          if (advertType != null) 'type': advertType,
          'page': page,
          'limit': limit,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (radiusKm != null) 'radiusKm': radiusKm,
          if (species != null) 'species': species,
          if (gender != null) 'gender': gender,
          if (vaccinated != null) 'vaccinated': vaccinated.toString(),
          if (breed != null) 'breed': breed,
          if (startsWith != null && startsWith.trim().isNotEmpty)
            'startsWith': startsWith.trim(),
          if (minAgeMonths != null) 'minAgeMonths': minAgeMonths,
          if (maxAgeMonths != null) 'maxAgeMonths': maxAgeMonths,
        },
      );
      final List<dynamic> raw = response.data['items'] ?? [];
      return (
        items: raw.map((j) => Pet.fromJson(j)).toList(),
        hasMore: response.data['hasMore'] == true,
      );
    });
  }

  Future<Pet> getPetById(String petId) async {
    try {
      // Tercih: /api/pets/:id, 404 gelirse /api/adverts/:id fallback
      try {
        final response = await _dio.get(
          '/api/pets/$petId',
          options: Options(
            responseType: ResponseType.json,
            receiveDataWhenStatusError: true,
          ),
        );
        final petJson = response.data['pet'] ?? response.data;
        if (petJson is Map<String, dynamic>) {
          return Pet.fromJson(Map<String, dynamic>.from(petJson));
        }
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;
      }

      final advertsRes = await _dio.get(
        '/api/adverts/$petId',
        options: Options(
          responseType: ResponseType.json,
          receiveDataWhenStatusError: true,
        ),
      );
      final advertsJson =
          advertsRes.data['pet'] ??
          advertsRes.data['advert'] ??
          advertsRes.data;
      if (advertsJson is! Map<String, dynamic>) {
        throw PetDetailException(
          'Sunucudan beklenmeyen cevap alindi.',
          statusCode: advertsRes.statusCode,
        );
      }
      return Pet.fromJson(Map<String, dynamic>.from(advertsJson));
    } on DioException catch (e) {
      final message = _extractMessage(e) ?? 'Ilan detayi yuklenemedi.';
      throw PetDetailException(message, statusCode: e.response?.statusCode);
    } catch (e) {
      throw PetDetailException('Ilan detayi islenirken hata olustu: $e');
    }
  }

  Future<Pet> createPet({
    required String name,
    required String species,
    String? breed,
    required String gender,
    required int ageMonths,
    String? bio,
    required bool vaccinated,
    Map<String, dynamic>? location,
    String advertType = 'adoption',
    List<String>? images,
    List<String>? videos,
  }) {
    return _guard(() async {
      final response = await _dio.post(
        '/api/pets',
        data: {
          'name': name,
          'species': species,
          'breed': breed,
          'gender': gender,
          'ageMonths': ageMonths,
          'bio': bio,
          'vaccinated': vaccinated,
          'location': location,
          'advertType': advertType,
          if (images != null) 'images': images,
          if (videos != null) 'videos': videos,
        },
      );
      final pet = Pet.fromJson(response.data['pet']);
      await _updateCachedFeed((current) => [pet, ...current]);
      return pet;
    });
  }

  Future<Pet> updatePet(
    String petId, {
    required String name,
    required String species,
    String? breed,
    required String gender,
    required int ageMonths,
    String? bio,
    required bool vaccinated,
    Map<String, dynamic>? location,
    String? advertType,
    List<String>? images,
    List<String>? videos,
  }) {
    return _guard(() async {
      final response = await _dio.put(
        '/api/pets/$petId',
        data: {
          'name': name,
          'species': species,
          'breed': breed,
          'gender': gender,
          'ageMonths': ageMonths,
          'bio': bio,
          'vaccinated': vaccinated,
          'location': location,
          if (advertType != null) 'advertType': advertType,
          if (images != null) 'images': images,
          if (videos != null) 'videos': videos,
        },
      );
      final updated = Pet.fromJson(response.data['pet']);
      await _updateCachedFeed((current) {
        return current.map((p) => p.id == updated.id ? updated : p).toList();
      });
      return updated;
    });
  }

  Future<String> uploadPetImage(String petId, XFile imageFile) {
    return _guard(() async {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });
      final response = await _dio.post(
        '/api/pets/$petId/images',
        data: formData,
      );
      return response.data['url'];
    });
  }

  Future<String> uploadPetVideo(String petId, XFile videoFile) {
    return _guard(() async {
      final fileName = videoFile.path.split('/').last;
      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          videoFile.path,
          filename: fileName,
        ),
      });
      final response = await _dio.post(
        '/api/pets/$petId/videos',
        data: formData,
      );
      return response.data['url'];
    });
  }

  Future<String> uploadImageFile(XFile imageFile) {
    return _guard(() async {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });
      final response = await _dio.post('/api/uploads/images', data: formData);
      return response.data['url'];
    });
  }

  Future<String> uploadVideoFile(XFile videoFile) {
    return _guard(() async {
      final fileName = videoFile.path.split('/').last;
      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          videoFile.path,
          filename: fileName,
        ),
      });
      final response = await _dio.post('/api/uploads/videos', data: formData);
      return response.data['url'];
    });
  }

  Future<void> deletePet(String petId) {
    return _guard(() async {
      await _dio.delete('/api/pets/$petId');
      await _updateCachedFeed(
        (current) => current.where((p) => p.id != petId).toList(),
      );
    });
  }

  Future<LikeResult> likePet(String petId) {
    return _guard(() async {
      final response = await _dio.post('/api/interactions/like/$petId');
      final bool didMatch = response.data['match'] ?? false;
      PetOwner? matchedUser;
      if (didMatch && response.data['matchedWith'] != null) {
        matchedUser = PetOwner.fromJson(response.data['matchedWith']);
      }
      return LikeResult(didMatch: didMatch, matchedUser: matchedUser);
    });
  }

  Future<void> passPet(String petId) {
    return _guard(() async {
      await _dio.post('/api/interactions/pass/$petId');
    });
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map &&
        data['message'] is String &&
        (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    if (e.message != null && e.message!.isNotEmpty) {
      return e.message;
    }
    return null;
  }

  Future<void> _updateCachedFeed(List<Pet> Function(List<Pet>) updater) async {
    final current = await getCachedFeed();
    final updated = updater(current);
    await cacheFeed(updated);
  }

  Future<List<Map<String, dynamic>>> getPetTimeline(String petId) {
    return _guard(() async {
      final response = await _dio.get('/api/pets/$petId/timeline');
      final list = response.data['timeline'] as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getHealthSummary() {
    return _guard(() async {
      final response = await _dio.get('/api/pets/health-summary');
      final list = response.data['summary'] as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }
}

final petHealthSummaryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(petsRepositoryProvider).getHealthSummary();
});

class PetDetailException implements Exception {
  final String message;
  final int? statusCode;

  PetDetailException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

final allPetsProvider = FutureProvider<List<Pet>>((ref) {
  final repository = ref.watch(petsRepositoryProvider);
  return repository.getPets();
});

final adoptionAdvertsProvider = FutureProvider<List<Pet>>((ref) {
  final repository = ref.watch(petsRepositoryProvider);
  return repository.getAdoptionAdverts();
});

final matingAdvertsProvider = FutureProvider<List<Pet>>((ref) {
  final repository = ref.watch(petsRepositoryProvider);
  return repository.getMatingAdverts();
});

// myPetsProvider — stale-while-revalidate (TTL 30min)
class _MyPetsNotifier extends AsyncNotifier<List<Pet>> {
  static const _cacheKey = 'cache_my_pets_v1';

  @override
  Future<List<Pet>> build() async {
    final repo = ref.read(petsRepositoryProvider);
    return CacheService.staleWhileRevalidate<List<Pet>>(
      key: _cacheKey,
      ttl: const Duration(minutes: 30),
      fetch: () => repo.getMyPets(),
      fromJson: (raw) => (raw as List)
          .map((e) => Pet.fromJson(e as Map<String, dynamic>))
          .toList(),
      toJson: (list) => list.map((e) => e.toJson()).toList(),
      onUpdate: (fresh) => state = AsyncData(fresh),
    );
  }

  Future<void> refresh() async {
    await CacheService.invalidate(_cacheKey);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(petsRepositoryProvider).getMyPets(),
    );
  }
}

final myPetsProvider = AsyncNotifierProvider<_MyPetsNotifier, List<Pet>>(
  _MyPetsNotifier.new,
);

final myAdvertsProvider = FutureProvider.autoDispose.family<List<Pet>, String?>(
  (ref, advertType) {
    final repository = ref.watch(petsRepositoryProvider);
    final user = ref.watch(authProvider);
    if (user == null) return Future.value(<Pet>[]);
    return repository.getMyAdverts(advertType: advertType);
  },
);

class PetFeedNotifier extends AsyncNotifier<List<Pet>> {
  late final PetsRepository _repository;

  @override
  Future<List<Pet>> build() async {
    _repository = ref.read(petsRepositoryProvider);
    final cached = await _repository.getCachedFeed();
    if (cached.isNotEmpty) {
      state = AsyncData(cached);
    }
    final fresh = await _repository.getPetFeed();
    await _repository.cacheFeed(fresh);
    return fresh;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final fresh = await _repository.getPetFeed();
      await _repository.cacheFeed(fresh);
      return fresh;
    });
  }

  Future<void> optimisticAdd(Pet pet) async {
    final current = state.valueOrNull ?? [];
    final updated = [pet, ...current.where((p) => p.id != pet.id)];
    state = AsyncData(updated);
    await _repository.cacheFeed(updated);
  }
}

final petFeedProvider = AsyncNotifierProvider<PetFeedNotifier, List<Pet>>(
  PetFeedNotifier.new,
);

class PaginatedAdvertsState {
  final List<Pet> items;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int page;

  const PaginatedAdvertsState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.page = 0,
  });

  PaginatedAdvertsState copyWith({
    List<Pet>? items,
    bool? isLoading,
    bool? hasMore,
    String? error,
    bool clearError = false,
    int? page,
  }) {
    return PaginatedAdvertsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
    );
  }
}

class PaginatedAdvertsNotifier extends StateNotifier<PaginatedAdvertsState> {
  PaginatedAdvertsNotifier(this._repository, this._advertType)
    : super(const PaginatedAdvertsState()) {
    loadMore();
  }

  final PetsRepository _repository;
  final String _advertType;
  static const _limit = 10;

  double? _lat;
  double? _lng;
  String? _species;
  String? _breed;
  String? _gender;
  bool? _vaccinated;
  String? _startsWith;
  int? _minAgeMonths;
  int? _maxAgeMonths;

  void setLocation(double lat, double lng) {
    _lat = lat;
    _lng = lng;
  }

  void clearLocation() {
    _lat = null;
    _lng = null;
  }

  void setFilter({
    String? species,
    String? breed,
    String? gender,
    bool? vaccinated,
    String? startsWith,
    int? minAgeMonths,
    int? maxAgeMonths,
  }) {
    _species = species;
    _breed = breed;
    _gender = gender;
    _vaccinated = vaccinated;
    _startsWith = startsWith;
    _minAgeMonths = minAgeMonths;
    _maxAgeMonths = maxAgeMonths;
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final nextPage = state.page + 1;
      final result = await _repository.getPetsPaginated(
        advertType: _advertType,
        page: nextPage,
        limit: _limit,
        lat: _lat,
        lng: _lng,
        radiusKm: (_lat != null) ? 25 : null,
        species: _species,
        breed: _breed,
        gender: _gender,
        vaccinated: _vaccinated,
        startsWith: _startsWith,
        minAgeMonths: _minAgeMonths,
        maxAgeMonths: _maxAgeMonths,
      );
      state = state.copyWith(
        items: [...state.items, ...result.items],
        isLoading: false,
        hasMore: result.hasMore,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = const PaginatedAdvertsState();
    await loadMore();
  }
}

final adoptionPaginatedProvider =
    StateNotifierProvider<PaginatedAdvertsNotifier, PaginatedAdvertsState>(
      (ref) => PaginatedAdvertsNotifier(
        ref.read(petsRepositoryProvider),
        'adoption',
      ),
    );

final matingPaginatedProvider =
    StateNotifierProvider<PaginatedAdvertsNotifier, PaginatedAdvertsState>(
      (ref) =>
          PaginatedAdvertsNotifier(ref.read(petsRepositoryProvider), 'mating'),
    );

// ─── Yakındaki İlanlar ────────────────────────────────────────────────────────

class NearbyAdsFilter {
  final String? advertType; // null = tümü
  final String? species; // null = tümü
  final bool? vaccinated; // null = fark etmez
  final double radiusKm;
  final String? breed; // null = tümü

  const NearbyAdsFilter({
    this.advertType,
    this.species,
    this.vaccinated,
    this.radiusKm = 25,
    this.breed,
  });

  NearbyAdsFilter copyWith({
    Object? advertType = _sentinel,
    Object? species = _sentinel,
    Object? vaccinated = _sentinel,
    double? radiusKm,
    Object? breed = _sentinel,
  }) {
    return NearbyAdsFilter(
      advertType: advertType == _sentinel
          ? this.advertType
          : advertType as String?,
      species: species == _sentinel ? this.species : species as String?,
      vaccinated: vaccinated == _sentinel
          ? this.vaccinated
          : vaccinated as bool?,
      radiusKm: radiusKm ?? this.radiusKm,
      breed: breed == _sentinel ? this.breed : breed as String?,
    );
  }

  int get activeCount =>
      (advertType != null ? 1 : 0) +
      (species != null ? 1 : 0) +
      (vaccinated != null ? 1 : 0) +
      (breed != null ? 1 : 0);
}

const _sentinel = Object();

class NearbyAdsState {
  final List<Pet> items;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;
  final double? lat;
  final double? lng;
  final bool locationLoading;
  final NearbyAdsFilter filter;

  const NearbyAdsState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 0,
    this.error,
    this.lat,
    this.lng,
    this.locationLoading = false,
    this.filter = const NearbyAdsFilter(),
  });

  NearbyAdsState copyWith({
    List<Pet>? items,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
    bool clearError = false,
    double? lat,
    double? lng,
    bool? locationLoading,
    NearbyAdsFilter? filter,
  }) {
    return NearbyAdsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: clearError ? null : (error ?? this.error),
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      locationLoading: locationLoading ?? this.locationLoading,
      filter: filter ?? this.filter,
    );
  }
}

class NearbyAdsNotifier extends StateNotifier<NearbyAdsState> {
  NearbyAdsNotifier(this._repository) : super(const NearbyAdsState());

  final PetsRepository _repository;
  static const _limit = 10;

  void setLocation(double lat, double lng) {
    state = state.copyWith(lat: lat, lng: lng, locationLoading: false);
    _reset();
  }

  void setLocationLoading(bool v) => state = state.copyWith(locationLoading: v);

  void setError(String msg) =>
      state = state.copyWith(error: msg, locationLoading: false);

  void applyFilter(NearbyAdsFilter filter) {
    state = state.copyWith(filter: filter);
    _reset();
  }

  Future<void> _reset() async {
    state = state.copyWith(items: [], page: 0, hasMore: true, clearError: true);
    await loadMore();
  }

  Future<void> refresh() => _reset();

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.lat == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final nextPage = state.page + 1;
      final f = state.filter;
      final result = await _repository.getPetsPaginated(
        advertType: f.advertType,
        page: nextPage,
        limit: _limit,
        lat: state.lat,
        lng: state.lng,
        radiusKm: f.radiusKm,
        species: f.species,
        vaccinated: f.vaccinated,
        breed: f.breed,
      );
      state = state.copyWith(
        items: [...state.items, ...result.items],
        isLoading: false,
        hasMore: result.hasMore,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final nearbyAdsProvider =
    StateNotifierProvider<NearbyAdsNotifier, NearbyAdsState>(
      (ref) => NearbyAdsNotifier(ref.read(petsRepositoryProvider)),
    );
