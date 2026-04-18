import 'dart:io';
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:evcilhayvan_mobil2/core/widgets/state_views.dart';
import 'package:evcilhayvan_mobil2/core/widgets/premium_card.dart';
import 'package:evcilhayvan_mobil2/core/widgets/animated_empty_state.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:evcilhayvan_mobil2/core/providers/socket_provider.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../data/repositories/pet_sitter_repository.dart';
import '../../domain/models/sitter_booking_model.dart';
import '../../domain/models/pet_sitter_model.dart';
import 'live_tracking_screen.dart';
import 'care_report_screen.dart';
import 'booking_timeline_screen.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> with SingleTickerProviderStateMixin {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.bookingsTitle),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: l10n.bookingsTabMine),
            Tab(text: l10n.bookingsTabIncoming),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _BookingsList(provider: myBookingsProvider, isSitter: false),
          _BookingsList(provider: incomingBookingsProvider, isSitter: true),
        ],
      ),
    );
  }
}

class _BookingsList extends ConsumerStatefulWidget {
  final ProviderBase<AsyncValue<List<SitterBookingModel>>> provider;
  final bool isSitter;
  const _BookingsList({required this.provider, required this.isSitter});

  @override
  ConsumerState<_BookingsList> createState() => _BookingsListState();
}

class _BookingsListState extends ConsumerState<_BookingsList> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(widget.provider);

    return async.when(
      loading: () => const Center(child: PawLoading()),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(widget.provider)),
      data: (bookings) {
        final l10n = AppLocalizations.of(context)!;

        // Günlere göre grupla (startDate baz alınır)
        final Map<DateTime, List<SitterBookingModel>> eventMap = {};
        for (final b in bookings) {
          final day = _norm(b.startDate);
          eventMap.putIfAbsent(day, () => []).add(b);
        }

        List<SitterBookingModel> Function(DateTime) getForDay =
            (day) => eventMap[_norm(day)] ?? [];

        final visibleBookings = _selectedDay != null
            ? getForDay(_selectedDay!)
            : bookings;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(widget.provider),
          child: CustomScrollView(
            slivers: [
              // Haftalık takvim şeridi
              SliverToBoxAdapter(
                child: TableCalendar<SitterBookingModel>(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      _selectedDay != null && _norm(day) == _norm(_selectedDay!),
                  eventLoader: getForDay,
                  calendarFormat: CalendarFormat.week,
                  availableCalendarFormats: const {
                    CalendarFormat.week: 'Hafta',
                    CalendarFormat.month: 'Ay',
                  },
                  locale: 'tr_TR',
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = _norm(selected) == _norm(_selectedDay ?? DateTime(0))
                          ? null
                          : selected;
                      _focusedDay = focused;
                    });
                  },
                  onPageChanged: (focused) => setState(() => _focusedDay = focused),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF52B788).withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF2D6A4F),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Color(0xFF52B788),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              // Filtre bilgisi
              if (_selectedDay != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: Row(
                      children: [
                        Text(
                          '${_selectedDay!.day}.${_selectedDay!.month}.${_selectedDay!.year} — ${visibleBookings.length} rezervasyon',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF2D6A4F), fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _selectedDay = null),
                          child: const Text('Tümü', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                ),
              // Rezervasyon listesi
              if (visibleBookings.isEmpty)
                SliverFillRemaining(
                  child: AnimatedEmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: _selectedDay != null ? 'Bu günde rezervasyon yok' : l10n.bookingsEmptyTitle,
                    subtitle: _selectedDay == null ? l10n.bookingsEmptySubtitle : null,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _BookingCard(
                        booking: visibleBookings[i],
                        isSitter: widget.isSitter,
                        ref: ref,
                        index: i,
                      ),
                      childCount: visibleBookings.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final SitterBookingModel booking;
  final bool isSitter;
  final WidgetRef ref;
  final int index;
  const _BookingCard({
    required this.booking,
    required this.isSitter,
    required this.ref,
    required this.index,
  });

  Color _statusColor() {
    switch (booking.status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return const Color(0xFF52B788);
      case 'active':
        return const Color(0xFF1D3557);
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'completed':
        return const Color(0xFF2D6A4F);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy');
    final l10n = AppLocalizations.of(context)!;
    final accent = _statusColor();

    return PremiumCard(
      accentColor: accent,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  isSitter
                      ? (booking.ownerName ?? l10n.bookingsOwnerLabel)
                      : (booking.sitterName ?? l10n.bookingsSitterLabel),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withOpacity(0.3)),
                ),
                child: Text(
                  booking.statusLabel,
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Service & pet
          Text(
            '${booking.serviceLabel} - ${booking.petName ?? "Pet"}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 4),
          // Dates
          Row(
            children: [
              Icon(Icons.date_range_rounded, size: 15, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                '${fmt.format(booking.startDate)} - ${fmt.format(booking.endDate)}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Price
          Text(
            '${booking.totalPrice.toInt()} TL',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF2D6A4F)),
          ),
          if (booking.isActive || booking.isCompleted || booking.earningsPaused)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Guncel odeme: ${booking.payableAmount.toStringAsFixed(0)} TL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: booking.earningsPaused ? Colors.orange.shade800 : Colors.grey.shade700,
                ),
              ),
            ),
          if (booking.earningsPaused)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  'Canli konum kesildi. Odeme gecici olarak durduruldu.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          // Notes
          if (booking.notes?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                booking.notes!,
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          // Actions — pending (sitter)
          if (booking.isPending && isSitter)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => _respond(context, 'accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.bookingsAccept),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => _respond(context, 'rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.bookingsReject),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Action — walk controls (sitter) + live tracking (owner)
          if (booking.needsPickup || booking.canTrackLive) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: isSitter
                  ? _SitterWalkControls(booking: booking, ref: ref)
                  : booking.canTrackLive
                      ? _OwnerTrackButton(booking: booking)
                      : const _OwnerWaitingCard(),
            ),
          ],
          // Action — mark complete (sitter)
          // Action — care report + timeline (boarding/home_sitting)
          if ((booking.isAccepted || booking.isActive) &&
              (booking.serviceType == 'boarding' || booking.serviceType == 'home_sitting'))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  if (isSitter)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final res = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => CareReportScreen(booking: booking, dayNumber: 1)),
                          );
                          if (res == true) ref.invalidate(myBookingsProvider);
                        },
                        icon: const Icon(Icons.assignment_add, size: 18),
                        label: const Text('Günlük Rapor'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2D6A4F),
                          side: const BorderSide(color: Color(0xFF2D6A4F)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  if (isSitter) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => BookingTimelineScreen(booking: booking)),
                      ),
                      icon: const Icon(Icons.timeline, size: 18),
                      label: const Text('Bakım Günlüğü'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF52B788),
                        side: const BorderSide(color: Color(0xFF52B788)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Walk photo sharing (sitter) + gallery (both)
          if (booking.isActive || booking.isCompleted)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  if (isSitter)
                    Expanded(
                      child: _WalkPhotoUploadButton(booking: booking, ref: ref),
                    ),
                  if (isSitter) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => _WalkPhotoGalleryScreen(bookingId: booking.id)),
                      ),
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text('Fotoğraf Günlüğü'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        side: const BorderSide(color: Colors.deepPurple),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Action — review (owner)
          if (booking.isCompleted && !booking.hasReview && !isSitter)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _showReviewSheet(context),
                  icon: const Icon(Icons.star_rounded, size: 20),
                  label: Text(l10n.bookingsReview),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D6A4F),
                    side: const BorderSide(color: Color(0xFF2D6A4F)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn(duration: 280.ms).slideY(begin: 0.05);
  }

  Future<void> _respond(BuildContext context, String status) async {
    try {
      await ref.read(petSitterRepositoryProvider).updateBookingStatus(booking.id, status);
      ref.invalidate(myBookingsProvider);
      ref.invalidate(incomingBookingsProvider);
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.bookingsActionErr(e.toString()))));
      }
    }
  }

  void _showReviewSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    double rating = 5;
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(
          builder: (ctx, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.bookingsReviewDialogTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              // Animated stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setS(() => rating = i + 1.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: i < rating ? Colors.amber : Colors.grey.shade300,
                      size: 36,
                    ).animate(delay: Duration(milliseconds: i * 80)).scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 300.ms,
                      curve: Curves.elasticOut,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                decoration: InputDecoration(
                  hintText: l10n.bookingsReviewHint,
                  filled: true,
                  fillColor: const Color(0xFFF4FAF6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l10n.bookingsReviewCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await ref.read(petSitterRepositoryProvider).updateBookingStatus(
                            booking.id, 'completed',
                            rating: rating, comment: commentCtrl.text.trim(),
                          );
                          ref.invalidate(myBookingsProvider);
                        } catch (e) {
                          if (context.mounted) {
                            final l10n2 = AppLocalizations.of(context)!;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n2.bookingsActionErr(e.toString()))),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l10n.bookingsReviewSend),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bakıcı: Gezi/Hizmet ekranına git
class _SitterWalkControls extends StatelessWidget {
  final SitterBookingModel booking;
  final WidgetRef ref;
  const _SitterWalkControls({required this.booking, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LiveTrackingScreen(booking: booking, isSitter: true),
          ),
        ),
        icon: Icon(booking.needsPickup ? Icons.pets : Icons.location_on, size: 20),
        label: const Text('Gezi Ekranına Geç'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D6A4F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// Bakıcı: Fotoğraf Paylaş butonu
class _WalkPhotoUploadButton extends StatefulWidget {
  final SitterBookingModel booking;
  final WidgetRef ref;
  const _WalkPhotoUploadButton({required this.booking, required this.ref});

  @override
  State<_WalkPhotoUploadButton> createState() => _WalkPhotoUploadButtonState();
}

class _WalkPhotoUploadButtonState extends State<_WalkPhotoUploadButton> {
  bool _uploading = false;

  Future<void> _pick() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      await widget.ref.read(petSitterRepositoryProvider).uploadWalkPhoto(
        widget.booking.id,
        File(file.path),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf pet sahibine gönderildi!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _uploading ? null : _pick,
      icon: _uploading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.camera_alt, size: 18),
      label: Text(_uploading ? 'Yükleniyor...' : 'Foto Paylaş'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2D6A4F),
        side: const BorderSide(color: Color(0xFF2D6A4F)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// Fotoğraf Günlüğü ekranı
class _WalkPhotoGalleryScreen extends ConsumerWidget {
  final String bookingId;
  const _WalkPhotoGalleryScreen({required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(_walkPhotosProvider(bookingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotoğraf Günlüğü'),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
      ),
      body: photosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Yüklenemedi: $e')),
        data: (photos) {
          if (photos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz fotoğraf paylaşılmadı', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: photos.length,
            itemBuilder: (ctx, i) {
              final photo = photos[i];
              final rawUrl = photo['url']?.toString() ?? '';
              final url = rawUrl.startsWith('http') ? rawUrl : '$apiBaseUrl$rawUrl';
              return GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(url, fit: BoxFit.contain),
                        ),
                        if (photo['caption']?.toString().isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              photo['caption'].toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(url, fit: BoxFit.cover),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

final _walkPhotosProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, bookingId) => ref.read(petSitterRepositoryProvider).getWalkPhotos(bookingId),
);

class _OwnerWaitingCard extends StatelessWidget {
  const _OwnerWaitingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1DE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9C46A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.schedule, color: Color(0xFFB08900), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bakici henuz kopegi teslim almadi. Teslim alindiginda canli konum otomatik acilacak.',
              style: TextStyle(
                color: Color(0xFF7A5C00),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sahip: Canlı Konum butonu
class _OwnerTrackButton extends StatelessWidget {
  final SitterBookingModel booking;
  const _OwnerTrackButton({required this.booking});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: () => context.pushNamed(
          'live-tracking',
          extra: booking,
        ),
        icon: const Icon(Icons.location_on, size: 20),
        label: const Text('Canlı Konum Takip'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF52B788),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
