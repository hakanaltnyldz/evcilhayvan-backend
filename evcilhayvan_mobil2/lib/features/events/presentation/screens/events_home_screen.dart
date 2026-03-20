import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/state_views.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import '../../data/repositories/event_repository.dart';
import '../../domain/models/pet_event_model.dart';
import '../widgets/event_card.dart';

class EventsHomeScreen extends ConsumerStatefulWidget {
  const EventsHomeScreen({super.key});

  @override
  ConsumerState<EventsHomeScreen> createState() => _EventsHomeScreenState();
}

class _EventsHomeScreenState extends ConsumerState<EventsHomeScreen> {
  double? _lat;
  double? _lng;
  bool _locationLoading = false;
  String? _selectedCategory;

  List<Map<String, Object?>> _getCategories(AppLocalizations l10n) => [
    {'value': null, 'label': l10n.eventsCatAll, 'icon': Icons.apps},
    {'value': 'park_meetup', 'label': l10n.eventsCatPark, 'icon': Icons.park},
    {'value': 'adoption_day', 'label': l10n.eventsCatAdoption, 'icon': Icons.volunteer_activism},
    {'value': 'training', 'label': l10n.eventsCatTraining, 'icon': Icons.school},
    {'value': 'competition', 'label': l10n.eventsCatCompetition, 'icon': Icons.emoji_events},
    {'value': 'grooming', 'label': l10n.eventsCatGrooming, 'icon': Icons.content_cut},
    {'value': 'health', 'label': l10n.eventsCatHealth, 'icon': Icons.local_hospital},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _locationLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _locationLoading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() { _lat = pos.latitude; _lng = pos.longitude; _locationLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = _getCategories(l10n);
    final params = EventListParams(lat: _lat, lng: _lng, category: _selectedCategory);
    final eventsAsync = ref.watch(eventListProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventsTitle2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: l10n.eventsMyEventsTooltip,
            onPressed: () => context.push('/events/attending'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/events/create'),
        icon: const Icon(Icons.add),
        label: Text(l10n.eventsCreateBtn),
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Location status
          if (_locationLoading)
            const LinearProgressIndicator()
          else if (_lat == null)
            _LocationBanner(onRetry: _fetchLocation),

          // Category filter
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final cat = categories[i];
                final catValue = cat['value'] as String?;
                final selected = _selectedCategory == catValue;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      cat['icon'] as IconData,
                      size: 16,
                      color: selected ? Colors.white : AppPalette.primary,
                    ),
                    label: Text(cat['label'] as String),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCategory = catValue),
                    selectedColor: AppPalette.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    checkmarkColor: Colors.white,
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),

          // Events list
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(eventListProvider(params)),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return EmptyState(
                    icon: Icons.celebration_outlined,
                    title: l10n.eventsEmptyTitle,
                    subtitle: l10n.eventsEmptySubtitle,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(eventListProvider(params)),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                    itemCount: events.length,
                    itemBuilder: (context, i) => EventCard(
                      event: events[i],
                      onTap: () => context.push('/events/${events[i].id}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _LocationBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.location_off, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(AppLocalizations.of(context)!.eventsLocationBannerText, style: const TextStyle(fontSize: 13)),
          ),
          TextButton(onPressed: onRetry, child: Text(AppLocalizations.of(context)!.eventsLocationBannerBtn)),
        ],
      ),
    );
  }
}
