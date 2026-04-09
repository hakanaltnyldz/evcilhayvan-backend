import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/widgets/state_views.dart';
import 'package:evcilhayvan_mobil2/core/widgets/premium_card.dart';
import 'package:evcilhayvan_mobil2/core/widgets/animated_empty_state.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:evcilhayvan_mobil2/core/providers/socket_provider.dart';
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

class _BookingsList extends ConsumerWidget {
  final ProviderBase<AsyncValue<List<SitterBookingModel>>> provider;
  final bool isSitter;
  const _BookingsList({required this.provider, required this.isSitter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);

    return async.when(
      loading: () => const Center(child: PawLoading()),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(provider)),
      data: (bookings) {
        if (bookings.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return AnimatedEmptyState(
            icon: Icons.calendar_today_outlined,
            title: l10n.bookingsEmptyTitle,
            subtitle: l10n.bookingsEmptySubtitle,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, i) => _BookingCard(
              booking: bookings[i],
              isSitter: isSitter,
              ref: ref,
              index: i,
            ),
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
          if (booking.isAccepted) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: isSitter
                  ? _SitterWalkControls(booking: booking, ref: ref)
                  : _OwnerTrackButton(booking: booking),
            ),
          ],
          // Action — mark complete (sitter)
          if (booking.isAccepted && isSitter)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _respond(context, 'completed'),
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: Text(l10n.bookingsMarkCompleted),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D6A4F),
                    side: const BorderSide(color: Color(0xFF2D6A4F)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          // Action — care report + timeline (boarding/home_sitting)
          if (booking.isAccepted &&
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
        icon: const Icon(Icons.directions_walk, size: 20),
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
