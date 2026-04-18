import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/widgets/premium_card.dart';
import 'package:evcilhayvan_mobil2/core/widgets/interactive_scale.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/core/widgets/gradient_button.dart';
import 'package:evcilhayvan_mobil2/core/widgets/section_header.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/messages/data/repositories/message_repository.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import '../../data/repositories/pet_sitter_repository.dart';
import '../../domain/models/pet_sitter_model.dart';
import 'availability_screen.dart';

class SitterDetailScreen extends ConsumerWidget {
  final String sitterId;
  const SitterDetailScreen({super.key, required this.sitterId});

  String _r(String url) => url.startsWith('http') ? url : '$apiBaseUrl$url';

  IconData _serviceIcon(String type) {
    switch (type) {
      case 'walking':
        return Icons.directions_walk;
      case 'home_sitting':
        return Icons.home;
      case 'boarding':
        return Icons.hotel;
      case 'daycare':
        return Icons.wb_sunny;
      case 'grooming':
        return Icons.content_cut;
      default:
        return Icons.pets;
    }
  }

  static Future<void> _showAddReviewDialog(BuildContext context, WidgetRef ref, PetSitterModel sitter) async {
    int selectedRating = 0;
    final commentController = TextEditingController();
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Bakıcıyı Değerlendir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(
                    i < selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => selectedRating = i + 1),
                )),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Yorumunuzu yazın (isteğe bağlı)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: saving || selectedRating == 0 ? null : () async {
                setState(() => saving = true);
                try {
                  final repo = ref.read(petSitterRepositoryProvider);
                  await repo.addSitterReview(
                    sitter.id,
                    rating: selectedRating,
                    comment: commentController.text.trim(),
                  );
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ref.invalidate(sitterDetailProvider(sitter.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Yorumunuz kaydedildi!')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    setState(() => saving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
              ),
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Gönder'),
            ),
          ],
        ),
      ),
    );
    commentController.dispose();
  }

  Widget _sectionTitle(String title, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SectionHeader(title: title),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sitterDetailProvider(sitterId));
    final user = ref.watch(authProvider);

    return async.when(
      loading: () => const Scaffold(body: Center(child: PawLoading())),
      error: (e, _) {
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(appBar: AppBar(), body: Center(child: Text('${l10n.sitterErrorPrefix}$e')));
      },
      data: (data) {
        final l10n = AppLocalizations.of(context)!;
        final sitter = data['sitter'] as PetSitterModel;
        final reviews = data['reviews'] as List<SitterReview>;
        final photo = sitter.avatar?.isNotEmpty == true
            ? sitter.avatar!
            : (sitter.photos.isNotEmpty ? sitter.photos.first : '');

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppPalette.appBarDark,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      photo.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _r(photo), fit: BoxFit.cover)
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1B4332),
                                    Color(0xFF2D6A4F)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                  child: Icon(Icons.person,
                                      size: 80, color: Color(0xFFD8F3DC))),
                            ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black26],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(sitter.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          if (sitter.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD8F3DC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF52B788)),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified,
                                        size: 14,
                                        color: Color(0xFF2D6A4F)),
                                    const SizedBox(width: 4),
                                    Text(l10n.sitterVerifiedLabel,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2D6A4F))),
                                  ]),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Rating + Distance
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                              '${sitter.rating.toStringAsFixed(1)} (${sitter.reviewCount} yorum)',
                              style: Theme.of(context).textTheme.bodyMedium),
                          if (sitter.distanceKm != null) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.location_on,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            Text(
                                '${sitter.distanceKm!.toStringAsFixed(1)} km',
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Availability badge with pulse animation
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sitter.availability
                              ? const Color(0xFFD8F3DC)
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: sitter.availability
                                ? const Color(0xFF52B788)
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: sitter.availability
                                    ? const Color(0xFF2D6A4F)
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              sitter.availability
                                  ? l10n.sitterAvailableNow
                                  : l10n.sitterCurrentlyBusy,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: sitter.availability
                                    ? const Color(0xFF2D6A4F)
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate(
                            onPlay: (controller) => sitter.availability
                                ? controller.repeat(reverse: true)
                                : null,
                          )
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.03, 1.03),
                            duration: 1200.ms,
                            curve: Curves.easeInOut,
                          ),
                      const SizedBox(height: 16),

                      // Bio
                      if (sitter.bio?.isNotEmpty == true) ...[
                        _sectionTitle(l10n.sitterAboutSection, Icons.info_outline),
                        Text(sitter.bio!,
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 16),
                      ],

                      // Services + Prices
                      _sectionTitle(l10n.sitterServicesAndPrices, Icons.handyman),
                      ...sitter.services.asMap().entries.map((entry) {
                        final i = entry.key;
                        final s = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PremiumCard(
                            accentColor: const Color(0xFF52B788),
                            enableScale: false,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD8F3DC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_serviceIcon(s.type),
                                      color: const Color(0xFF2D6A4F),
                                      size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(s.label,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15))),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (s.pricePerHour > 0)
                                      Text(l10n.sitterHourlyRate(s.pricePerHour.toInt()),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF2D6A4F))),
                                    if (s.pricePerDay > 0)
                                      Text(l10n.sitterDailyRate(s.pricePerDay.toInt()),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600)),
                                  ],
                                ),
                              ],
                            ),
                          )
                              .animate(
                                  delay:
                                      Duration(milliseconds: 100 * i))
                              .fadeIn(duration: 300.ms)
                              .slideX(begin: 0.05),
                        );
                      }),
                      const SizedBox(height: 16),

                      // Species
                      _sectionTitle('Bakilan Turler', Icons.pets),
                      Text(sitter.speciesLabel,
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 16),

                      // Müsaitlik Takvimi
                      _sectionTitle('Müsaitlik Takvimi', Icons.calendar_month_outlined),
                      _AvailabilityCalendar(sitter: sitter),
                      const SizedBox(height: 16),

                      // Portfolio Fotoğrafları
                      if (sitter.photos.isNotEmpty) ...[
                        _sectionTitle('Fotoğraflar (${sitter.photos.length})', Icons.photo_library),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: sitter.photos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (ctx, i) {
                              final url = _r(sitter.photos[i]);
                              return GestureDetector(
                                onTap: () => showDialog(
                                  context: ctx,
                                  builder: (_) => Dialog.fullscreen(
                                    child: Stack(
                                      children: [
                                        Center(child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url))),
                                        Positioned(
                                          top: 40, right: 16,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                            onPressed: () => Navigator.of(ctx).pop(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(imageUrl: url, width: 100, height: 100, fit: BoxFit.cover),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Address
                      if (sitter.address?.isNotEmpty == true) ...[
                        _sectionTitle('Konum', Icons.location_on),
                        Row(children: [
                          const Icon(Icons.location_on,
                              color: Color(0xFF2D6A4F)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(sitter.address!)),
                        ]),
                        const SizedBox(height: 16),
                      ],

                      // Reviews
                      if (reviews.isNotEmpty) ...[
                        _sectionTitle(
                            'Yorumlar (${reviews.length})', Icons.reviews),
                        ...reviews.asMap().entries.map((entry) {
                          final i = entry.key;
                          final r = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: PremiumCard(
                              enableScale: false,
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            const Color(0xFFD8F3DC),
                                        child: Text(
                                            (r.ownerName ?? '?')[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                                color: Color(0xFF2D6A4F),
                                                fontWeight:
                                                    FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(r.ownerName ?? 'Kullanici',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const Spacer(),
                                      ...List.generate(
                                          5,
                                          (j) => Icon(
                                                j < r.rating
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.amber,
                                                size: 14,
                                              )),
                                    ],
                                  ),
                                  if (r.comment?.isNotEmpty == true) ...[
                                    const SizedBox(height: 8),
                                    Text(r.comment!),
                                  ],
                                ],
                              ),
                            )
                                .animate(
                                    delay:
                                        Duration(milliseconds: 80 * i))
                                .fadeIn(duration: 280.ms)
                                .slideY(begin: 0.05),
                          );
                        }),
                      ],

                      // Yorum yap butonu (kendi profili değilse)
                      if (user != null && (sitter.userId == null || sitter.userId != user.id)) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _showAddReviewDialog(context, ref, sitter),
                          icon: const Icon(Icons.rate_review_outlined, size: 18),
                          label: const Text('Yorum Yap'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2D6A4F),
                            side: const BorderSide(color: Color(0xFF2D6A4F)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
              ),
            ],
          ),
          bottomNavigationBar: user != null
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        // Kendi profili ise — müsaitlik takvimi butonu
                        if (sitter.userId != null && sitter.userId == user.id) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => AvailabilityScreen(sitterId: sitter.id)),
                              ),
                              icon: const Icon(Icons.calendar_month),
                              label: const Text('Müsaitlik'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2D6A4F),
                                side: const BorderSide(color: Color(0xFF2D6A4F)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                        if (sitter.userId != null && sitter.userId != user.id) ...[
                          Expanded(
                            child: _MessageSitterButton(
                                sitter: sitter, userId: user.id),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (sitter.availability && sitter.userId != user.id)
                          Expanded(
                            child: GradientButton(
                              label: l10n.sitterBook,
                              icon: Icons.calendar_month_rounded,
                              onPressed: () => context.pushNamed(
                                'sitter-booking',
                                pathParameters: {'sitterId': sitter.id},
                                extra: sitter,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _MessageSitterButton extends ConsumerStatefulWidget {
  final PetSitterModel sitter;
  final String userId;
  const _MessageSitterButton({required this.sitter, required this.userId});

  @override
  ConsumerState<_MessageSitterButton> createState() => _MessageSitterButtonState();
}

class _MessageSitterButtonState extends ConsumerState<_MessageSitterButton> {
  bool _loading = false;

  Future<void> _openChat() async {
    final sitterUserId = widget.sitter.userId;
    if (sitterUserId == null || sitterUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu bakıcının hesabı henüz bağlanmamış.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(messageRepositoryProvider);
      final conv = await repo.createOrGetConversation(
        participantId: sitterUserId,
        currentUserId: widget.userId,
      );
      if (mounted) {
        context.pushNamed('chat',
            pathParameters: {'conversationId': conv.id},
            extra: {'name': widget.sitter.displayName, 'avatar': widget.sitter.avatar});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAccount = widget.sitter.userId != null && widget.sitter.userId!.isNotEmpty;
    final button = OutlinedButton.icon(
      onPressed: (_loading || !hasAccount) ? null : _openChat,
      icon: _loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.message_outlined),
      label: const Text('Mesajla', style: TextStyle(fontSize: 16)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2D6A4F),
        side: BorderSide(color: hasAccount ? const Color(0xFF2D6A4F) : Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
    if (!hasAccount) {
      return Tooltip(
        message: 'Bu bakıcı henüz hesabını bağlamamış',
        child: Opacity(opacity: 0.4, child: button),
      );
    }
    return button;
  }
}

// ── Müsaitlik Takvimi Widget ──
class _AvailabilityCalendar extends StatefulWidget {
  final PetSitterModel sitter;
  const _AvailabilityCalendar({required this.sitter});

  @override
  State<_AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<_AvailabilityCalendar> {
  DateTime _viewMonth = DateTime.now();

  Set<String> get _blockedSet {
    final dates = widget.sitter.blockedDates ?? [];
    return dates.map((d) => '${d.year}-${d.month}-${d.day}').toSet();
  }

  bool _isBlocked(DateTime day) {
    return _blockedSet.contains('${day.year}-${day.month}-${day.day}');
  }

  bool _isPast(DateTime day) {
    final today = DateTime.now();
    return day.isBefore(DateTime(today.year, today.month, today.day));
  }

  void _prevMonth() => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1));
  void _nextMonth() => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDay = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    // Pazartesi=0 başlangıç
    final startWeekday = (firstDay.weekday - 1) % 7;
    final monthNames = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Ay navigasyonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0xFF2D6A4F)),
                  onPressed: _prevMonth,
                ),
                Expanded(
                  child: Text(
                    '${monthNames[_viewMonth.month - 1]} ${_viewMonth.year}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF2D6A4F)),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          // Gün başlıkları
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: ['Pzt','Sal','Çar','Per','Cum','Cmt','Paz'].map((d) => Expanded(
                child: Text(d, textAlign: TextAlign.center, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.grey)),
              )).toList(),
            ),
          ),
          const SizedBox(height: 6),
          // Takvim grid
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: startWeekday + daysInMonth,
              itemBuilder: (ctx, i) {
                if (i < startWeekday) return const SizedBox();
                final day = DateTime(_viewMonth.year, _viewMonth.month, i - startWeekday + 1);
                final isToday = day.year == DateTime.now().year && day.month == DateTime.now().month && day.day == DateTime.now().day;
                final blocked = _isBlocked(day);
                final past = _isPast(day);

                Color bg;
                Color textColor;
                if (blocked) {
                  bg = Colors.red.shade100;
                  textColor = Colors.red.shade700;
                } else if (past) {
                  bg = Colors.transparent;
                  textColor = Colors.grey.shade400;
                } else if (isToday) {
                  bg = const Color(0xFF2D6A4F);
                  textColor = Colors.white;
                } else {
                  bg = const Color(0xFFD8F3DC);
                  textColor = const Color(0xFF1B4332);
                }

                return Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: blocked ? Border.all(color: Colors.red.shade300, width: 1) : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
                    ),
                  ),
                );
              },
            ),
          ),
          // Lejant
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(const Color(0xFFD8F3DC), 'Müsait'),
                const SizedBox(width: 16),
                _legendDot(Colors.red.shade100, 'Kapalı'),
                const SizedBox(width: 16),
                _legendDot(const Color(0xFF2D6A4F), 'Bugün'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ],
  );
}
