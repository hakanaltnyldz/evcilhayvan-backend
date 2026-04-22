import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/animated_empty_state.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';

import '../../data/repositories/pet_sitter_repository.dart';
import '../../domain/models/pet_sitter_model.dart';
import '../../domain/models/sitter_booking_model.dart';
import '../../domain/models/sitter_financial_summary_model.dart';
import 'sitter_financials_screen.dart';

final _sitterDashboardProvider =
    FutureProvider.autoDispose<_SitterDashboardData?>((ref) async {
      final repo = ref.watch(petSitterRepositoryProvider);
      final profile = await repo.mySitterProfile();
      if (profile == null) return null;

      final bookings = await repo.incomingBookings();
      List<SitterReview> reviews = const [];
      SitterFinancialSummaryModel? financials;
      try {
        final detail = await repo.getSitter(profile.id);
        reviews = (detail['reviews'] as List<SitterReview>?) ?? const [];
      } catch (_) {}

      try {
        financials = await repo.getMyFinancialSummary();
      } catch (_) {
        financials = null;
      }

      return _SitterDashboardData(
        profile: profile,
        bookings: bookings,
        reviews: reviews,
        financials: financials,
      );
    });

class SitterDashboardScreen extends ConsumerStatefulWidget {
  const SitterDashboardScreen({super.key});

  @override
  ConsumerState<SitterDashboardScreen> createState() =>
      _SitterDashboardScreenState();
}

class _SitterDashboardScreenState extends ConsumerState<SitterDashboardScreen> {
  bool _togglingAvailability = false;

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(_sitterDashboardProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        title: const Text('Bakici Dashboard'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(_sitterDashboardProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: PawLoading()),
        error: (error, _) => _DashboardMessage(
          icon: Icons.error_outline,
          title: 'Dashboard yuklenemedi',
          subtitle: error.toString(),
          actionLabel: 'Tekrar Dene',
          onAction: () => ref.invalidate(_sitterDashboardProvider),
        ),
        data: (data) {
          if (data == null) {
            return _DashboardMessage(
              icon: Icons.pets_outlined,
              title: 'Dashboard icin bakici profili gerekli',
              subtitle:
                  'Once profilinizi olusturun. Sonrasinda rezervasyonlariniz ve performansiniz burada toplanacak.',
              actionLabel: 'Bakici Profili Olustur',
              onAction: () => context.pushNamed('become-sitter'),
            );
          }

          final pending = data.bookings
              .where((b) => b.status == 'pending')
              .length;
          final accepted = data.bookings
              .where((b) => b.status == 'accepted')
              .length;
          final active = data.bookings
              .where((b) => b.status == 'active')
              .length;
          final completed = data.bookings
              .where((b) => b.status == 'completed')
              .toList();
          final now = DateTime.now();
          final monthRevenue =
              data.financials?.thisMonthRevenue ??
              completed
                  .where(
                    (b) =>
                        b.endDate.year == now.year &&
                        b.endDate.month == now.month,
                  )
                  .fold<double>(0, (sum, b) => sum + _amount(b));
          final totalRevenue =
              data.financials?.totalRevenue ??
              completed.fold<double>(0, (sum, b) => sum + _amount(b));
          final pipeline =
              data.financials?.pipelineRevenue ??
              data.bookings
                  .where((b) => b.status == 'accepted' || b.status == 'active')
                  .fold<double>(0, (sum, b) => sum + _amount(b));
          final upcoming =
              data.bookings
                  .where(
                    (b) =>
                        (b.status == 'accepted' || b.status == 'active') &&
                        b.endDate.isAfter(now),
                  )
                  .toList()
                ..sort((a, b) => a.startDate.compareTo(b.startDate));
          final serviceCounts = <String, int>{};
          for (final booking in data.bookings) {
            serviceCounts.update(
              booking.serviceLabel,
              (value) => value + 1,
              ifAbsent: () => 1,
            );
          }
          final serviceEntries = serviceCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final maxServiceCount = serviceEntries.isEmpty
              ? 1
              : serviceEntries.first.value;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_sitterDashboardProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeroCard(
                  profile: data.profile,
                  pending: pending,
                  active: active,
                  togglingAvailability: _togglingAvailability,
                  onToggleAvailability: () => _toggleAvailability(data.profile),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metricCard(
                      context,
                      'Bekleyen',
                      '$pending',
                      'Onay bekleyen rezervasyon',
                      Icons.mark_email_unread_outlined,
                      Colors.orange.shade700,
                    ),
                    _metricCard(
                      context,
                      'Aktif',
                      '$active',
                      'Devam eden hizmet',
                      Icons.pets_outlined,
                      const Color(0xFF1D3557),
                    ),
                    _metricCard(
                      context,
                      'Tamamlanan',
                      '${completed.length}',
                      'Kapanan rezervasyon',
                      Icons.task_alt_rounded,
                      const Color(0xFF2D6A4F),
                    ),
                    _metricCard(
                      context,
                      'Puan',
                      data.profile.rating.toStringAsFixed(1),
                      '${data.profile.reviewCount} yorum',
                      Icons.star_rounded,
                      Colors.amber.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  'Hizli Aksiyonlar',
                  'Rezervasyon, profil ve takvim ekranlarina buradan gecin.',
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _actionChip(
                        'Rezervasyonlar',
                        Icons.assignment_outlined,
                        () => context.pushNamed('sitter-bookings'),
                      ),
                      _actionChip(
                        'Profili Duzenle',
                        Icons.edit_outlined,
                        () => context.pushNamed(
                          'become-sitter',
                          extra: data.profile,
                        ),
                      ),
                      _actionChip(
                        'Musaitlik Takvimi',
                        Icons.calendar_month_outlined,
                        () => context.pushNamed(
                          'sitter-availability',
                          pathParameters: {'id': data.profile.id},
                        ),
                      ),
                      _actionChip(
                        'Portfolio',
                        Icons.collections_bookmark_outlined,
                        () => context.pushNamed('sitter-portfolio'),
                      ),
                      _actionChip(
                        'Kazanc Raporu',
                        Icons.insights_outlined,
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SitterFinancialsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  'Gelir Ozeti',
                  'Mevcut rezervasyonlardan turetilen operasyonel finans gorunumu.',
                  Column(
                    children: [
                      _financeRow(
                        context,
                        'Bu ay kazanilan',
                        _currency(monthRevenue),
                        highlight: const Color(0xFF2D6A4F),
                      ),
                      const Divider(height: 22),
                      _financeRow(
                        context,
                        'Toplam tamamlanan gelir',
                        _currency(totalRevenue),
                      ),
                      const Divider(height: 22),
                      _financeRow(context, 'Pipeline', _currency(pipeline)),
                      const Divider(height: 22),
                      _financeRow(context, 'Kabul edilen is', '$accepted'),
                      if (data.financials != null) ...[
                        const Divider(height: 22),
                        _financeRow(
                          context,
                          'Duraklayan odeme',
                          _currency(data.financials!.pausedRevenue),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  'Hizmet Dagilimi',
                  'Talep yogunlugunun hangi hizmetlere kaydigini gosterir.',
                  serviceEntries.isEmpty
                      ? const Text(
                          'Henuz hizmet gecmisi olusmadi.',
                          style: TextStyle(color: Colors.grey),
                        )
                      : Column(
                          children: serviceEntries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${entry.value} is',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: entry.value / maxServiceCount,
                                      minHeight: 10,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF52B788),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  'Yaklasan Isler',
                  'Baslangic tarihi yaklasan aktif ve onayli rezervasyonlar.',
                  upcoming.isEmpty
                      ? const Text(
                          'Yaklasan rezervasyon bulunmuyor.',
                          style: TextStyle(color: Colors.grey),
                        )
                      : Column(
                          children: upcoming.take(3).map(_bookingTile).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  'Son Yorumlar',
                  'Musteri memnuniyetini tek panelden takip edin.',
                  data.reviews.isEmpty
                      ? const Text(
                          'Henuz yorum yok.',
                          style: TextStyle(color: Colors.grey),
                        )
                      : Column(
                          children: data.reviews
                              .take(3)
                              .map(_reviewTile)
                              .toList(),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleAvailability(PetSitterModel profile) async {
    if (_togglingAvailability) return;
    setState(() => _togglingAvailability = true);
    try {
      final nextValue = await ref
          .read(petSitterRepositoryProvider)
          .toggleAvailability(profile.id);
      ref.invalidate(_sitterDashboardProvider);
      ref.invalidate(mySitterProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextValue
                ? 'Profil musait olarak acildi.'
                : 'Profil musait degil olarak guncellendi.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Musaitlik guncellenemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _togglingAvailability = false);
    }
  }
}

class _SitterDashboardData {
  const _SitterDashboardData({
    required this.profile,
    required this.bookings,
    required this.reviews,
    required this.financials,
  });

  final PetSitterModel profile;
  final List<SitterBookingModel> bookings;
  final List<SitterReview> reviews;
  final SitterFinancialSummaryModel? financials;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.profile,
    required this.pending,
    required this.active,
    required this.togglingAvailability,
    required this.onToggleAvailability,
  });

  final PetSitterModel profile;
  final int pending;
  final int active;
  final bool togglingAvailability;
  final VoidCallback onToggleAvailability;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white24,
                backgroundImage: profile.avatar != null
                    ? NetworkImage(profile.avatar!)
                    : null,
                child: profile.avatar == null
                    ? const Icon(Icons.pets, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.address ?? 'Adres eklenmedi',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroChip(
                profile.isVerified
                    ? 'Dogrulanmis Profil'
                    : 'Onay Bekleyen Profil',
                Icons.verified_outlined,
              ),
              _heroChip('$pending talep sirada', Icons.schedule_outlined),
              _heroChip('$active aktif hizmet', Icons.directions_walk_outlined),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Musaitlik Durumu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  profile.availability ? 'Acik' : 'Kapali',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 8),
                IgnorePointer(
                  ignoring: togglingAvailability,
                  child: Switch.adaptive(
                    value: profile.availability,
                    activeColor: const Color(0xFF95D5B2),
                    onChanged: (_) => onToggleAvailability(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedEmptyState(icon: icon, title: title, subtitle: subtitle),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _metricCard(
  BuildContext context,
  String title,
  String value,
  String subtitle,
  IconData icon,
  Color accent,
) {
  final width = (MediaQuery.of(context).size.width - 44) / 2;
  return Container(
    width: width,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(height: 14),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

Widget _section(
  BuildContext context,
  String title,
  String subtitle,
  Widget child,
) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            height: 1.4,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

Widget _actionChip(String label, IconData icon, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Ink(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F3DC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2D6A4F)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}

Widget _financeRow(
  BuildContext context,
  String label,
  String value, {
  Color? highlight,
}) {
  return Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      Text(
        value,
        style: TextStyle(fontWeight: FontWeight.w800, color: highlight),
      ),
    ],
  );
}

Widget _bookingTile(SitterBookingModel booking) {
  final formatter = DateFormat('dd MMM', 'tr_TR');
  return Builder(
    builder: (context) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFD8F3DC),
            backgroundImage: booking.petPhoto != null
                ? NetworkImage(booking.petPhoto!)
                : null,
            child: booking.petPhoto == null
                ? const Icon(Icons.pets, color: Color(0xFF2D6A4F))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.petName ?? 'Evcil hayvan',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.serviceLabel} • ${formatter.format(booking.startDate)} - ${formatter.format(booking.endDate)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            booking.statusLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

Widget _reviewTile(SitterReview review) {
  return Builder(
    builder: (context) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFD8F3DC),
                backgroundImage: review.ownerAvatar != null
                    ? NetworkImage(review.ownerAvatar!)
                    : null,
                child: review.ownerAvatar == null
                    ? Text(
                        review.ownerName == null || review.ownerName!.isEmpty
                            ? '?'
                            : review.ownerName!.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF1B4332),
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.ownerName ?? 'Musteri',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                review.rating.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if ((review.comment ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _heroChip(String label, IconData icon) {
  return Builder(
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

double _amount(SitterBookingModel booking) =>
    booking.payableAmount > 0 ? booking.payableAmount : booking.totalPrice;

String _currency(double value) => NumberFormat.currency(
  locale: 'tr_TR',
  symbol: 'TL',
  decimalDigits: 0,
).format(value);
