import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/state_views.dart';
import '../../data/repositories/pet_sitter_repository.dart';
import '../../domain/models/sitter_booking_model.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezervasyonlar'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Rezervasyonlarim'),
            Tab(text: 'Gelen Talepler'),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(provider)),
      data: (bookings) {
        if (bookings.isEmpty) {
          return const EmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'Henüz rezervasyon yok',
            subtitle: 'Onaylanan rezervasyonlarınız burada görünecek.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, i) => _BookingCard(booking: bookings[i], isSitter: isSitter, ref: ref),
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
  const _BookingCard({required this.booking, required this.isSitter, required this.ref});

  Color _statusColor() {
    switch (booking.status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.red;
      case 'cancelled': return Colors.grey;
      case 'completed': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    isSitter ? (booking.ownerName ?? 'Sahip') : (booking.sitterName ?? 'Bakici'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(booking.statusLabel,
                      style: TextStyle(color: _statusColor(), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${booking.serviceLabel} - ${booking.petName ?? "Pet"}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text('${fmt.format(booking.startDate)} - ${fmt.format(booking.endDate)}'),
            Text('${booking.totalPrice.toInt()} TL', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            if (booking.notes?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(booking.notes!, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ),
            // Actions
            if (booking.isPending && isSitter)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _respond(context, 'accepted'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: const Text('Kabul Et'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _respond(context, 'rejected'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Reddet'),
                      ),
                    ),
                  ],
                ),
              ),
            if (booking.isAccepted && isSitter)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ElevatedButton.icon(
                  onPressed: () => _respond(context, 'completed'),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Tamamlandi Olarak Isaretle'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
              ),
            if (booking.isCompleted && !booking.hasReview && !isSitter)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ElevatedButton.icon(
                  onPressed: () => _showReviewDialog(context),
                  icon: const Icon(Icons.star),
                  label: const Text('Degerlendir'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _respond(BuildContext context, String status) async {
    try {
      await ref.read(petSitterRepositoryProvider).updateBookingStatus(booking.id, status);
      ref.invalidate(myBookingsProvider);
      ref.invalidate(incomingBookingsProvider);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  void _showReviewDialog(BuildContext context) {
    double rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Bakiciyi Degerlendir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber),
                  onPressed: () => setS(() => rating = i + 1.0),
                )),
              ),
              TextField(
                controller: commentCtrl,
                decoration: const InputDecoration(hintText: 'Yorum (opsiyonel)', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(petSitterRepositoryProvider).updateBookingStatus(
                    booking.id, 'completed',
                    rating: rating, comment: commentCtrl.text.trim(),
                  );
                  ref.invalidate(myBookingsProvider);
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                }
              },
              child: const Text('Gonder'),
            ),
          ],
        ),
      ),
    );
  }
}
