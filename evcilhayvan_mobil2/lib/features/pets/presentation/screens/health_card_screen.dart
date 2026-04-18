import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';

// Provider
final _healthCardProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, petId) async {
  final dio = ApiClient().dio;
  final r = await dio.get('/api/pets/$petId/health-card');
  return Map<String, dynamic>.from(r.data as Map);
});

class HealthCardScreen extends ConsumerStatefulWidget {
  final String petId;
  const HealthCardScreen({super.key, required this.petId});

  @override
  ConsumerState<HealthCardScreen> createState() => _HealthCardScreenState();
}

class _HealthCardScreenState extends ConsumerState<HealthCardScreen> {
  final _qrKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/health_card.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Evcil hayvan sağlık kartım');
    } catch (_) {} finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_healthCardProvider(widget.petId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sağlık Kartı'),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _sharing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.share),
            onPressed: _sharing ? null : _share,
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: PawLoading()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (data) {
          final pet = data['pet'] as Map<String, dynamic>;
          final records = (data['healthRecords'] as List? ?? [])
              .cast<Map<String, dynamic>>();
          final qrData = 'evcilhayvan://pets/${pet['id']}/health-card';
          final vaccinationRecords = records.where((r) => r['type'] == 'vaccination').toList();
          final otherRecords = records.where((r) => r['type'] != 'vaccination').take(5).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // QR Kartı
                RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Pet bilgileri
                        Row(
                          children: [
                            Container(
                              width: 60, height: 60,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD8F3DC),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.pets, size: 32, color: Color(0xFF2D6A4F)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pet['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text('${pet['species'] ?? ''} • ${pet['breed'] ?? ''}',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                  if (pet['gender'] != null)
                                    Text(pet['gender'], style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        // QR
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 200,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF1B4332),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF2D6A4F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Veterinere gösterin', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Aşı kayıtları
                if (vaccinationRecords.isNotEmpty) ...[
                  _SectionTitle(title: 'Aşı Kayıtları', icon: Icons.vaccines),
                  const SizedBox(height: 8),
                  ...vaccinationRecords.map((r) => _HealthRecordTile(record: r)),
                  const SizedBox(height: 16),
                ],

                // Diğer sağlık kayıtları
                if (otherRecords.isNotEmpty) ...[
                  _SectionTitle(title: 'Son Sağlık Kayıtları', icon: Icons.medical_information),
                  const SizedBox(height: 8),
                  ...otherRecords.map((r) => _HealthRecordTile(record: r)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2D6A4F)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    );
  }
}

class _HealthRecordTile extends StatelessWidget {
  final Map<String, dynamic> record;
  const _HealthRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final date = record['date'] != null
        ? DateTime.tryParse(record['date'].toString())
        : null;
    final nextDue = record['nextDueDate'] != null
        ? DateTime.tryParse(record['nextDueDate'].toString())
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(color: Color(0xFFD8F3DC), shape: BoxShape.circle),
            child: Icon(_typeIcon(record['type'] as String? ?? ''), size: 18, color: const Color(0xFF2D6A4F)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record['title'] as String? ?? record['type'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (date != null)
                  Text(_fmt(date), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                if (nextDue != null)
                  Text('Hatırlatıcı: ${_fmt(nextDue)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF2D6A4F))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'vaccination': return Icons.vaccines;
      case 'checkup':     return Icons.health_and_safety;
      case 'medication':  return Icons.medication;
      case 'weight':      return Icons.monitor_weight;
      default:            return Icons.medical_information;
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
