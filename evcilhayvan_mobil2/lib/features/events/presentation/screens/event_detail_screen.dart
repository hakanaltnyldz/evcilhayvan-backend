import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/widgets/state_views.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../../domain/models/pet_event_model.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  String? _myStatus; // going / interested / not_going / null
  bool _statusLoading = false;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMyStatus();
  }

  Future<void> _loadMyStatus() async {
    try {
      final status = await ref.read(eventRepositoryProvider).myAttendanceStatus(widget.eventId);
      if (mounted) setState(() => _myStatus = status);
    } catch (_) {}
  }

  Future<void> _attend(String status) async {
    setState(() => _statusLoading = true);
    try {
      await ref.read(eventRepositoryProvider).attendEvent(widget.eventId, status);
      setState(() => _myStatus = status);
      ref.invalidate(eventDetailProvider(widget.eventId));
      ref.invalidate(myAttendingEventsProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final user = ref.watch(authProvider);

    return eventAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: e.toString(), onRetry: () => ref.invalidate(eventDetailProvider(widget.eventId))),
      ),
      data: (event) => Scaffold(
        backgroundColor: const Color(0xFFF4FAF6),
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(event, theme),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + cancelled
                    if (event.isCancelled)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                        child: const Row(children: [
                          Icon(Icons.cancel, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Bu etkinlik iptal edildi.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    if (event.isCancelled) const SizedBox(height: 12),

                    Text(event.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _CategoryRow(event: event),
                    const SizedBox(height: 16),

                    // Date & Time
                    _InfoCard(children: [
                      _InfoRow(icon: Icons.calendar_today, text: _formatDate(event.startDate)),
                      _InfoRow(icon: Icons.access_time, text: '${_formatTime(event.startDate)} - ${_formatTime(event.endDate)}'),
                    ]),
                    const SizedBox(height: 12),

                    // Location
                    if (event.address != null || event.venueName != null)
                      _InfoCard(children: [
                        if (event.venueName != null) _InfoRow(icon: Icons.place, text: event.venueName!),
                        if (event.address != null) _InfoRow(icon: Icons.map, text: event.address!),
                      ]),
                    if (event.address != null) const SizedBox(height: 12),

                    // Attendees
                    _InfoCard(children: [
                      _InfoRow(
                        icon: Icons.group,
                        text: event.maxAttendees != null
                            ? '${event.attendeeCount} / ${event.maxAttendees} katilimci'
                            : '${event.attendeeCount} katilimci',
                      ),
                      _InfoRow(
                        icon: Icons.monetization_on,
                        text: event.isFree ? 'Ucretsiz' : '${event.price.toInt()} TL',
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Description
                    Text('Etkinlik Hakkinda', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(event.description, style: const TextStyle(height: 1.5)),
                    const SizedBox(height: 16),

                    // Species
                    if (event.speciesAllowed.isNotEmpty && !event.speciesAllowed.contains('all')) ...[
                      Text('Katilabilecek Hayvanlar', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: event.speciesAllowed.map((s) => Chip(
                          label: Text(_speciesLabel(s)),
                          avatar: const Icon(Icons.pets, size: 16),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Organizer
                    if (event.organizerName != null) ...[
                      Text('Organizator', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _OrganizerCard(event: event),
                      const SizedBox(height: 16),
                    ],

                    // External link
                    if (event.externalLink != null && event.externalLink!.isNotEmpty) ...[
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse(event.externalLink!)),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Detaylar icin Ziyaret Et'),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Tags
                    if (event.tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        children: event.tags.map((t) => Chip(
                          label: Text('#$t'),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Attendance buttons
        bottomNavigationBar: user != null && !event.isCancelled
            ? _AttendanceBar(myStatus: _myStatus, loading: _statusLoading, onAttend: _attend, event: event)
            : null,
      ),
    );
  }

  Widget _buildSliverAppBar(PetEventModel event, ThemeData theme) {
    final photos = event.photos.isNotEmpty ? event.photos : (event.coverPhoto != null ? [event.coverPhoto!] : <String>[]);
    return SliverAppBar(
      expandedHeight: photos.isNotEmpty ? 260 : 0,
      pinned: true,
      backgroundColor: const Color(0xFF1B4332),
      foregroundColor: Colors.white,
      flexibleSpace: photos.isNotEmpty
          ? FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => _photoIndex = i),
                    itemBuilder: (_, i) {
                      final url = photos[i].startsWith('http') ? photos[i] : '$apiBaseUrl${photos[i]}';
                      return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover);
                    },
                  ),
                  if (photos.length > 1)
                    Positioned(
                      bottom: 12, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(photos.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _photoIndex == i ? 16 : 6, height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _photoIndex == i ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ),
                    ),
                ],
              ),
            )
          : null,
    );
  }

  String _formatDate(DateTime d) => DateFormat('dd MMMM yyyy, EEEE', 'tr').format(d);
  String _formatTime(DateTime d) => DateFormat('HH:mm').format(d);

  String _speciesLabel(String s) {
    switch (s) {
      case 'dog': return 'Kopek';
      case 'cat': return 'Kedi';
      case 'bird': return 'Kus';
      case 'rabbit': return 'Tavsan';
      default: return 'Diger';
    }
  }
}

class _CategoryRow extends StatelessWidget {
  final PetEventModel event;
  const _CategoryRow({required this.event});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFD8F3DC), borderRadius: BorderRadius.circular(20)),
          child: Text(event.categoryLabel, style: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2D6A4F).withOpacity(0.06), blurRadius: 12),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2D6A4F)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _OrganizerCard extends StatelessWidget {
  final PetEventModel event;
  const _OrganizerCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = event.organizerAvatar != null
        ? (event.organizerAvatar!.startsWith('http') ? event.organizerAvatar! : '$apiBaseUrl${event.organizerAvatar}')
        : null;
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 12),
        Text(event.organizerName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

class _AttendanceBar extends StatelessWidget {
  final String? myStatus;
  final bool loading;
  final Function(String) onAttend;
  final PetEventModel event;

  const _AttendanceBar({required this.myStatus, required this.loading, required this.onAttend, required this.event});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (event.isFull && myStatus == null)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Kapasite doldu', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: (event.isFull && myStatus != 'going') ? null : () => onAttend('going'),
                          icon: Icon(myStatus == 'going' ? Icons.check_circle : Icons.event_available),
                          label: Text(myStatus == 'going' ? 'Katiliyorum' : 'Katil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: myStatus == 'going' ? const Color(0xFF52B788) : const Color(0xFF2D6A4F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onAttend('interested'),
                          icon: Icon(myStatus == 'interested' ? Icons.star : Icons.star_border),
                          label: const Text('Ilgimi Cekiyor', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: myStatus == 'interested' ? Colors.amber.shade700 : null,
                            side: myStatus == 'interested' ? BorderSide(color: Colors.amber.shade700) : null,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (myStatus != null && myStatus != 'not_going')
                    TextButton(
                      onPressed: () => onAttend('not_going'),
                      child: Text('Katilmayacagim', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                ],
              ),
      ),
    );
  }
}
