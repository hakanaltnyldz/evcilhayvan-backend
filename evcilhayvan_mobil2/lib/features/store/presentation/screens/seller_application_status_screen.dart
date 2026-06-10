// lib/features/store/presentation/screens/seller_application_status_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

final _myApplicationProvider = FutureProvider.autoDispose((ref) async {
  final response = await ApiClient().dio.get('/api/stores/application/status');
  return response.data['application'] as Map<String, dynamic>?;
});

class SellerApplicationStatusScreen extends ConsumerWidget {
  const SellerApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncApp = ref.watch(_myApplicationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sellerAppStatusTitle),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppPalette.storeWarmGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_myApplicationProvider),
          ),
        ],
      ),
      body: asyncApp.when(
        loading: () => const Center(child: PawLoading()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(l10n.sellerAppStatusLoadError),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(_myApplicationProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (application) {
          if (application == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: Colors.orange,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.sellerAppStatusNoneTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.sellerAppStatusNoneDesc,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.store_outlined),
                    label: Text(l10n.sellerAppStatusApply),
                    onPressed: () => context.pushNamed('store-apply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.storePrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return _ApplicationDetailView(application: application);
        },
      ),
    );
  }
}

class _ApplicationDetailView extends StatelessWidget {
  final Map<String, dynamic> application;

  const _ApplicationDetailView({required this.application});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = application['status'] as String? ?? 'pending';
    final createdAt = _parseDate(application['createdAt']);
    final rejectionReason = application['rejectionReason'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatusCard(status: status, createdAt: createdAt),
          const SizedBox(height: 16),
          _InfoCard(application: application),
          if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 16),
            _RejectionCard(reason: rejectionReason),
          ],
          if (status == 'rejected') ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.sellerAppStatusReapply),
                onPressed: () => context.pushNamed('store-apply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.storePrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}

class _StatusCard extends StatelessWidget {
  final String status;
  final DateTime? createdAt;

  const _StatusCard({required this.status, this.createdAt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (color, icon, title, subtitle) = switch (status) {
      'approved' => (
        Colors.green,
        Icons.check_circle,
        l10n.sellerAppStatusApprovedTitle,
        l10n.sellerAppStatusApprovedDesc,
      ),
      'rejected' => (
        Colors.red,
        Icons.cancel,
        l10n.sellerAppStatusRejectedTitle,
        l10n.sellerAppStatusRejectedDesc,
      ),
      _ => (
        Colors.orange,
        Icons.hourglass_empty,
        l10n.sellerAppStatusPendingTitle,
        l10n.sellerAppStatusPendingDesc,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
          if (createdAt != null) ...[
            const SizedBox(height: 12),
            Text(
              l10n.sellerAppStatusSubmittedAt(
                DateFormat('dd.MM.yyyy HH:mm').format(createdAt!),
              ),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Map<String, dynamic> application;

  const _InfoCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fields = [
      (l10n.sellerAppStatusCompanyName, application['companyName']),
      (
        l10n.applySellerCompanyTitleLabel.replaceAll(' *', ''),
        application['companyTitle'],
      ),
      (
        l10n.applySellerTaxNumberLabel.replaceAll(' *', ''),
        application['taxNumber'],
      ),
      (
        l10n.applySellerTaxOfficeLabel.replaceAll(' *', ''),
        application['taxOffice'],
      ),
      (
        l10n.applySellerAddressLabel.replaceAll(' *', ''),
        application['address'],
      ),
      (
        l10n.applySellerContactInfoLabel.replaceAll(' *', ''),
        application['contactInfo'],
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppPalette.storePrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business,
                  color: AppPalette.storePrimary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.sellerAppStatusInfoTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...fields
              .where((f) => f.$2 != null)
              .map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          f.$1,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          f.$2.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _RejectionCard extends StatelessWidget {
  final String reason;

  const _RejectionCard({required this.reason});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.sellerAppStatusRejectionReason,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(reason, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
