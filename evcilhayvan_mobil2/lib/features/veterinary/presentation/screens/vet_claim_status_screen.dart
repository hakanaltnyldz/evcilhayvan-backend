// lib/features/veterinary/presentation/screens/vet_claim_status_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';

final _myClaimsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ApiClient().dio;
  final response = await dio.get('/api/veterinaries/my-claim-status');
  final List<dynamic> raw = response.data['claims'] ?? [];
  return raw.whereType<Map<String, dynamic>>().toList();
});

class VetClaimStatusScreen extends ConsumerWidget {
  const VetClaimStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimsAsync = ref.watch(_myClaimsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Klinik Sahiplenme Taleplerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_myClaimsProvider),
          ),
        ],
      ),
      body: claimsAsync.when(
        data: (claims) {
          if (claims.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_hospital_outlined, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz klinik sahiplenme talebiniz yok.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_myClaimsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: claims.length,
              itemBuilder: (context, index) => _ClaimCard(claim: claims[index]),
            ),
          );
        },
        loading: () => const Center(child: PawLoading()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Talepler yüklenemedi: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(_myClaimsProvider),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim});

  final Map<String, dynamic> claim;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2D6A4F);
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'İnceleniyor';
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.tryParse(value.toString());
      if (dt == null) return '';
      return DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(dt.toLocal());
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = claim['status']?.toString() ?? 'pending';
    final color = _statusColor(status);
    final vetData = claim['vetId'];
    final vetName = vetData is Map ? vetData['name']?.toString() ?? 'Klinik' : 'Klinik';
    final vetAddress = vetData is Map ? vetData['address']?.toString() : null;
    final adminNote = claim['adminNote']?.toString() ?? '';
    final reviewedAt = claim['reviewedAt'];
    final createdAt = claim['createdAt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinic name + status chip
          Row(
            children: [
              const Icon(Icons.local_hospital_rounded, color: Color(0xFF40916C), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vetName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(status), size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(_statusText(status), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),

          if (vetAddress != null && vetAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(vetAddress, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Submitted role
          if (claim['role'] != null) ...[
            _InfoRow(label: 'Rol', value: claim['role'].toString()),
            const SizedBox(height: 4),
          ],

          // Submitted note
          if ((claim['note']?.toString() ?? '').isNotEmpty) ...[
            _InfoRow(label: 'Açıklama', value: claim['note'].toString()),
            const SizedBox(height: 4),
          ],

          // Dates
          if (createdAt != null) ...[
            _InfoRow(label: 'Başvuru Tarihi', value: _formatDate(createdAt)),
            const SizedBox(height: 4),
          ],
          if (reviewedAt != null) ...[
            _InfoRow(label: 'Karar Tarihi', value: _formatDate(reviewedAt)),
            const SizedBox(height: 4),
          ],

          // Admin note
          if (adminNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 14, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      adminNote,
                      style: TextStyle(fontSize: 13, color: color),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (status == 'pending') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top, size: 14, color: Colors.orange),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Talebiniz admin tarafından inceleniyor. Sonuç bildirim olarak iletilecektir.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}
