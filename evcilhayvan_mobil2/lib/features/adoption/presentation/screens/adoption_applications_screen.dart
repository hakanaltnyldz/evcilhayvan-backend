import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import '../../data/repositories/adoption_repository.dart';
import '../../domain/models/adoption_application.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';

class AdoptionApplicationsScreen extends ConsumerStatefulWidget {
  const AdoptionApplicationsScreen({super.key});

  @override
  ConsumerState<AdoptionApplicationsScreen> createState() => _AdoptionApplicationsScreenState();
}

class _AdoptionApplicationsScreenState extends ConsumerState<AdoptionApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.adoptionAppsTitle),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.adoptionAppsTabInbox),
            Tab(text: AppLocalizations.of(context)!.adoptionAppsTabSent),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InboxTab(),
          _SentTab(),
        ],
      ),
    );
  }
}

class _InboxTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(inboxAdoptionApplicationsProvider);

    return inboxAsync.when(
      loading: () => const Center(child: PawLoading()),
      error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.adoptionAppsErrGeneric(e.toString()))),
      data: (applications) {
        if (applications.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return _emptyState(context, Icons.inbox, l10n.adoptionAppsInboxEmpty, l10n.adoptionAppsInboxEmptyDesc);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(inboxAdoptionApplicationsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) => _ApplicationCard(
              application: applications[index],
              isInbox: true,
              onAccept: () => _respond(context, ref, applications[index], 'accept'),
              onReject: () => _respond(context, ref, applications[index], 'reject'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _respond(BuildContext context, WidgetRef ref, AdoptionApplication app, String action) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action == 'accept' ? l10n.adoptionAppsAcceptTitle : l10n.adoptionAppsRejectTitle),
        content: Text(action == 'accept'
            ? l10n.adoptionAppsAcceptContent
            : l10n.adoptionAppsRejectContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.adoptionAppsCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action == 'accept' ? l10n.adoptionAppsAcceptBtn : l10n.adoptionAppsRejectBtn,
                style: TextStyle(color: action == 'accept' ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final repo = ref.read(adoptionRepositoryProvider);
      final result = await repo.respondToApplication(app.id, action);
      ref.invalidate(inboxAdoptionApplicationsProvider);

      if (context.mounted) {
        final l10n2 = AppLocalizations.of(context)!;
        if (action == 'accept' && result.conversationId != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n2.adoptionAppsAcceptedStarted)));
          context.pushNamed('chat', pathParameters: {'conversationId': result.conversationId!});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(action == 'accept' ? l10n2.adoptionAppsAccepted : l10n2.adoptionAppsRejected)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        final l10n2 = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n2.adoptionAppsErrGeneric(e.toString())), backgroundColor: Colors.red));
      }
    }
  }
}

class _SentTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentAsync = ref.watch(sentAdoptionApplicationsProvider);

    return sentAsync.when(
      loading: () => const Center(child: PawLoading()),
      error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.adoptionAppsErrGeneric(e.toString()))),
      data: (applications) {
        if (applications.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return _emptyState(context, Icons.outbox, l10n.adoptionAppsSentEmpty, l10n.adoptionAppsSentEmptyDesc);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(sentAdoptionApplicationsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) => _ApplicationCard(
              application: applications[index],
              isInbox: false,
            ),
          ),
        );
      },
    );
  }
}

Widget _emptyState(BuildContext context, IconData icon, String title, String subtitle) {
  final theme = Theme.of(context);
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(color: Color(0xFFD8F3DC), shape: BoxShape.circle),
            child: Icon(icon, size: 48, color: const Color(0xFF2D6A4F)),
          ),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    ),
  );
}

class _ApplicationCard extends StatelessWidget {
  final AdoptionApplication application;
  final bool isInbox;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _ApplicationCard({required this.application, required this.isInbox, this.onAccept, this.onReject});

  Color get _statusColor {
    switch (application.status) {
      case 'ACCEPTED': return const Color(0xFF2D6A4F);
      case 'REJECTED': return Colors.red;
      case 'CANCELLED': return Colors.grey;
      default: return Colors.orange;
    }
  }

  String _getStatusText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (application.status) {
      case 'ACCEPTED': return l10n.adoptionAppsStatusAccepted;
      case 'REJECTED': return l10n.adoptionAppsStatusRejected;
      case 'CANCELLED': return l10n.adoptionAppsStatusCancelled;
      default: return l10n.adoptionAppsStatusPending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listing = application.listing;
    final applicant = application.applicantUser;
    final dateStr = '${application.createdAt.day.toString().padLeft(2, '0')}.${application.createdAt.month.toString().padLeft(2, '0')}.${application.createdAt.year}';

    final imageUrl = listing != null && listing.images.isNotEmpty
        ? (listing.images.first.startsWith('http') ? listing.images.first : '$apiBaseUrl${listing.images.first}')
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: const Color(0xFF2D6A4F).withOpacity(0.06), blurRadius: 12)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Pet image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: imageUrl != null
                        ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing?.name ?? 'Ilan',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (isInbox && applicant != null)
                        Text(AppLocalizations.of(context)!.adoptionAppsApplicant(applicant.name), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                      else if (listing?.species != null)
                        Text(listing!.species!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(dateStr, style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_getStatusText(context), style: theme.textTheme.labelSmall?.copyWith(color: _statusColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          // Not
          if (application.note != null && application.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(application.note!, style: theme.textTheme.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
              ),
            ),
          // Süreç zaman çizelgesi
          _ApplicationTimeline(status: application.status),

          // Aksiyonlar (sadece inbox + PENDING)
          if (isInbox && application.status == 'PENDING')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(AppLocalizations.of(context)!.adoptionAppsRejectBtn),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(AppLocalizations.of(context)!.adoptionAppsAcceptBtn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Accepted -> mesajlasma butonu
          if (application.status == 'ACCEPTED' && application.conversationId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.pushNamed('chat', pathParameters: {'conversationId': application.conversationId!}),
                  icon: const Icon(Icons.chat),
                  label: Text(AppLocalizations.of(context)!.adoptionAppsGoToChat),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A4F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFD8F3DC),
      child: const Center(child: Icon(Icons.pets, color: Color(0xFF2D6A4F))),
    );
  }
}

// ─── Başvuru Süreci Zaman Çizelgesi ─────────────────────────────────────────

class _ApplicationTimeline extends StatelessWidget {
  final String status;

  const _ApplicationTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(status, context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _TimelineStep(
              label: steps[i].$1,
              state: steps[i].$2,
            ),
            if (i < steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  color: steps[i].$2 == _StepState.done
                      ? const Color(0xFF2D6A4F).withOpacity(0.6)
                      : Theme.of(context).dividerColor,
                ),
              ),
          ],
        ],
      ),
    );
  }

  List<(String, _StepState)> _buildSteps(String status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'ACCEPTED':
        return [
          (l10n.adoptionAppsTimelineApplication, _StepState.done),
          (l10n.adoptionAppsTimelineReview, _StepState.done),
          (l10n.adoptionAppsTimelineApproval, _StepState.done),
          (l10n.adoptionAppsTimelineCompleted, _StepState.done),
        ];
      case 'REJECTED':
        return [
          (l10n.adoptionAppsTimelineApplication, _StepState.done),
          (l10n.adoptionAppsTimelineReview, _StepState.done),
          (l10n.adoptionAppsTimelineRejected, _StepState.error),
          ('', _StepState.inactive),
        ];
      case 'CANCELLED':
        return [
          (l10n.adoptionAppsTimelineApplication, _StepState.done),
          (l10n.adoptionAppsTimelineCancelled, _StepState.error),
          ('', _StepState.inactive),
          ('', _StepState.inactive),
        ];
      default: // PENDING
        return [
          (l10n.adoptionAppsTimelineApplication, _StepState.done),
          (l10n.adoptionAppsTimelineReview, _StepState.active),
          (l10n.adoptionAppsTimelineDecision, _StepState.inactive),
          (l10n.adoptionAppsTimelineCompleted, _StepState.inactive),
        ];
    }
  }
}

enum _StepState { done, active, error, inactive }

class _TimelineStep extends StatelessWidget {
  final String label;
  final _StepState state;

  const _TimelineStep({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox(width: 28);

    Color color;
    IconData icon;
    switch (state) {
      case _StepState.done:
        color = const Color(0xFF2D6A4F);
        icon = Icons.check_circle_rounded;
        break;
      case _StepState.active:
        color = const Color(0xFF52B788);
        icon = Icons.radio_button_checked_rounded;
        break;
      case _StepState.error:
        color = Colors.red;
        icon = Icons.cancel_rounded;
        break;
      case _StepState.inactive:
        color = Theme.of(context).colorScheme.outlineVariant;
        icon = Icons.circle_outlined;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: state == _StepState.inactive ? Theme.of(context).colorScheme.outlineVariant : color,
            fontWeight: state == _StepState.active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
