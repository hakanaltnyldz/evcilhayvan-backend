import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/widgets/state_views.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import '../../data/repositories/event_repository.dart';
import '../widgets/event_card.dart';

class MyEventsScreen extends ConsumerStatefulWidget {
  const MyEventsScreen({super.key});

  @override
  ConsumerState<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends ConsumerState<MyEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myEventsTitle),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: l10n.myEventsTabAttending),
            Tab(text: l10n.myEventsTabOrganized),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _EventList(provider: myAttendingEventsProvider),
          _EventList(provider: myOrganizedEventsProvider),
        ],
      ),
    );
  }
}

class _EventList extends ConsumerWidget {
  final ProviderBase<AsyncValue<List>> provider;
  const _EventList({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(provider)),
      data: (events) {
        if (events.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return EmptyState(
            icon: Icons.event_outlined,
            title: l10n.myEventsEmptyTitle,
            subtitle: l10n.myEventsEmptySubtitle,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            itemBuilder: (context, i) => EventCard(
              event: events[i],
              onTap: () => context.push('/events/${events[i].id}'),
            ),
          ),
        );
      },
    );
  }
}
