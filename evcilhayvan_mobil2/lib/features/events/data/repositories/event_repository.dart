import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../domain/models/pet_event_model.dart';

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ApiClient()),
);

class EventRepository {
  EventRepository(this._client);
  final ApiClient _client;
  Dio get _dio => _client.dio;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    } catch (e) {
      throw ApiError(e.toString());
    }
  }

  Future<List<PetEventModel>> listEvents({
    double? lat,
    double? lng,
    double radiusKm = 50,
    String? category,
    int page = 1,
  }) => _guard(() async {
    final r = await _dio.get(
      '/api/events',
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'radiusKm': radiusKm,
        if (category != null) 'category': category,
        'upcoming': 'true',
        'page': page,
        'limit': 20,
      },
    );
    final list = r.data['events'] as List? ?? [];
    return list
        .map((j) => PetEventModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  });

  Future<PetEventModel> getEvent(String id) => _guard(() async {
    final r = await _dio.get('/api/events/$id');
    return PetEventModel.fromJson(Map<String, dynamic>.from(r.data['event']));
  });

  Future<PetEventModel> createEvent(Map<String, dynamic> data) => _guard(
    () async {
      final r = await _dio.post('/api/events', data: data);
      return PetEventModel.fromJson(Map<String, dynamic>.from(r.data['event']));
    },
  );

  Future<String?> myAttendanceStatus(String eventId) => _guard(() async {
    final r = await _dio.get('/api/events/$eventId/attendance');
    final att = r.data['attendance'];
    if (att == null) return null;
    return att['status']?.toString();
  });

  Future<void> attendEvent(String eventId, String status) => _guard(() async {
    await _dio.post('/api/events/$eventId/attend', data: {'status': status});
  });

  Future<List<PetEventModel>> myAttendingEvents() => _guard(() async {
    final r = await _dio.get('/api/events/me/attending');
    final list = r.data['events'] as List? ?? [];
    return list
        .map((j) => PetEventModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  });

  Future<List<PetEventModel>> myOrganizedEvents() => _guard(() async {
    final r = await _dio.get('/api/events/me/organized');
    final list = r.data['events'] as List? ?? [];
    return list
        .map((j) => PetEventModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  });
}

// Providers
class EventListParams {
  final double? lat;
  final double? lng;
  final String? category;
  const EventListParams({this.lat, this.lng, this.category});
  @override
  bool operator ==(Object o) =>
      o is EventListParams &&
      lat == o.lat &&
      lng == o.lng &&
      category == o.category;
  @override
  int get hashCode => Object.hash(lat, lng, category);
}

final eventListProvider = FutureProvider.autoDispose
    .family<List<PetEventModel>, EventListParams>(
      (ref, p) => ref
          .watch(eventRepositoryProvider)
          .listEvents(lat: p.lat, lng: p.lng, category: p.category),
    );

class EventPaginatedState {
  final List<PetEventModel> events;
  final int currentPage;
  final bool hasMore;
  final bool loadingMore;
  final EventListParams params;
  const EventPaginatedState({
    required this.events,
    required this.currentPage,
    required this.hasMore,
    required this.loadingMore,
    required this.params,
  });
  EventPaginatedState copyWith({
    List<PetEventModel>? events,
    int? currentPage,
    bool? hasMore,
    bool? loadingMore,
  }) {
    return EventPaginatedState(
      events: events ?? this.events,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      params: params,
    );
  }
}

class EventPaginatedNotifier
    extends
        AutoDisposeFamilyAsyncNotifier<EventPaginatedState, EventListParams> {
  static const _pageSize = 20;

  @override
  Future<EventPaginatedState> build(EventListParams arg) async {
    final events = await ref
        .read(eventRepositoryProvider)
        .listEvents(
          lat: arg.lat,
          lng: arg.lng,
          category: arg.category,
          page: 1,
        );
    return EventPaginatedState(
      events: events,
      currentPage: 1,
      hasMore: events.length >= _pageSize,
      loadingMore: false,
      params: arg,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final more = await ref
          .read(eventRepositoryProvider)
          .listEvents(
            lat: current.params.lat,
            lng: current.params.lng,
            category: current.params.category,
            page: nextPage,
          );
      state = AsyncData(
        current.copyWith(
          events: [...current.events, ...more],
          currentPage: nextPage,
          hasMore: more.length >= _pageSize,
          loadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final events = await ref
          .read(eventRepositoryProvider)
          .listEvents(
            lat: arg.lat,
            lng: arg.lng,
            category: arg.category,
            page: 1,
          );
      return EventPaginatedState(
        events: events,
        currentPage: 1,
        hasMore: events.length >= _pageSize,
        loadingMore: false,
        params: arg,
      );
    });
  }
}

final eventPaginatedProvider = AsyncNotifierProvider.autoDispose
    .family<EventPaginatedNotifier, EventPaginatedState, EventListParams>(
      EventPaginatedNotifier.new,
    );

final eventDetailProvider = FutureProvider.autoDispose
    .family<PetEventModel, String>(
      (ref, id) => ref.watch(eventRepositoryProvider).getEvent(id),
    );

final myAttendingEventsProvider =
    FutureProvider.autoDispose<List<PetEventModel>>(
      (ref) => ref.watch(eventRepositoryProvider).myAttendingEvents(),
    );

final myOrganizedEventsProvider =
    FutureProvider.autoDispose<List<PetEventModel>>(
      (ref) => ref.watch(eventRepositoryProvider).myOrganizedEvents(),
    );
