// lib/features/health/presentation/screens/health_journal_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:evcilhayvan_mobil2/features/health/data/repositories/health_repository.dart';
import 'package:evcilhayvan_mobil2/features/health/domain/models/health_record_model.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final healthRepoProvider = Provider<HealthRepository>((_) => HealthRepository());

final healthRecordsProvider =
    FutureProvider.autoDispose.family<List<HealthRecord>, String>((ref, petId) {
  return ref.read(healthRepoProvider).getRecords(petId);
});

final weightChartProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, petId) {
  return ref.read(healthRepoProvider).getWeightChart(petId);
});

// ── Helpers ────────────────────────────────────────────────────────────────

const _typeLabels = {
  'weight': 'Kilo',
  'medication': 'İlaç',
  'vet_visit': 'Veteriner',
  'note': 'Not',
};

const _typeIcons = {
  'weight': Icons.monitor_weight_outlined,
  'medication': Icons.medication_outlined,
  'vet_visit': Icons.local_hospital_outlined,
  'note': Icons.notes_rounded,
};

const _typeColors = {
  'weight': Color(0xFF2BB673),
  'medication': Color(0xFF6C63FF),
  'vet_visit': Color(0xFFFF7A59),
  'note': Color(0xFF7C7BFF),
};

// ── Screen ─────────────────────────────────────────────────────────────────

class HealthJournalScreen extends ConsumerStatefulWidget {
  final String petId;
  final String petName;

  const HealthJournalScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  ConsumerState<HealthJournalScreen> createState() => _HealthJournalScreenState();
}

class _HealthJournalScreenState extends ConsumerState<HealthJournalScreen> {
  String? _filterType;
  final _fmt = DateFormat('dd MMM yyyy', 'tr');

  Future<void> _addRecord() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AddRecordDialog(petId: widget.petId),
    );
    if (result != null) {
      try {
        await ref.read(healthRepoProvider).addRecord(widget.petId, result);
        ref.invalidate(healthRecordsProvider(widget.petId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kayıt eklendi.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  Future<void> _delete(String recordId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kaydı Sil'),
        content: const Text('Bu sağlık kaydını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sil')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(healthRepoProvider).deleteRecord(recordId);
      ref.invalidate(healthRecordsProvider(widget.petId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Silinemedi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(healthRecordsProvider(widget.petId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.petName} Sağlık Günlüğü'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
        icon: const Icon(Icons.add),
        label: const Text('Kayıt Ekle'),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tümü'),
                  selected: _filterType == null,
                  onSelected: (_) => setState(() => _filterType = null),
                ),
                const SizedBox(width: 8),
                ...['weight', 'medication', 'vet_visit', 'note'].map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_typeLabels[t]!),
                      selected: _filterType == t,
                      avatar: Icon(_typeIcons[t]!, size: 16),
                      onSelected: (_) => setState(
                          () => _filterType = _filterType == t ? null : t),
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_filterType == 'weight') _WeightChartSection(petId: widget.petId),
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Yüklenemedi: $e'),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(healthRecordsProvider(widget.petId)),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
              data: (records) {
                final filtered = _filterType == null
                    ? records
                    : records.where((r) => r.type == _filterType).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.health_and_safety_outlined,
                            size: 64,
                            color: AppPalette.primary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          _filterType == null
                              ? 'Henüz sağlık kaydı yok'
                              : '${_typeLabels[_filterType]} kaydı yok',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                            'Sağ alttaki + butonuna basarak kayıt ekleyin'),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final record = filtered[index];
                    return _RecordCard(
                      record: record,
                      fmt: _fmt,
                      onDelete: () => _delete(record.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Record Card ────────────────────────────────────────────────────────────

class _RecordCard extends StatelessWidget {
  final HealthRecord record;
  final DateFormat fmt;
  final VoidCallback onDelete;

  const _RecordCard({
    required this.record,
    required this.fmt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[record.type] ?? AppPalette.primary;
    final icon = _typeIcons[record.type] ?? Icons.notes_rounded;
    final label = _typeLabels[record.type] ?? record.type;

    List<String> details = [];
    if (record.type == 'weight' && record.weightKg != null) {
      details.add('${record.weightKg!.toStringAsFixed(1)} kg');
    }
    if (record.type == 'medication') {
      if (record.medicationName != null) details.add(record.medicationName!);
      if (record.dosage != null) details.add('Doz: ${record.dosage}');
      if (record.frequency != null) details.add('Sıklık: ${record.frequency}');
    }
    if (record.type == 'vet_visit') {
      if (record.vetName != null) details.add('Veteriner: ${record.vetName}');
      if (record.diagnosis != null) details.add('Tanı: ${record.diagnosis}');
    }
    if (record.notes != null) details.add(record.notes!);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(label,
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 11)),
                      ),
                      const Spacer(),
                      Text(
                        fmt.format(record.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...details.map((d) => Text(d,
                        style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red.shade300,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weight Chart ───────────────────────────────────────────────────────────

class _WeightChartSection extends ConsumerWidget {
  final String petId;
  const _WeightChartSection({required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(weightChartProvider(petId));
    return chartAsync.when(
      loading: () => const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Kilo grafiği yüklenemedi',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(weightChartProvider(petId)),
              child: const Text('Yenile'),
            ),
          ],
        ),
      ),
      data: (data) {
        if (data.length < 2) return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2BB673).withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2BB673).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.show_chart, color: const Color(0xFF2BB673).withOpacity(0.5), size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kilo Takibi',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF2BB673),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Grafik için en az 2 kilo kaydı gerekli',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
        final spots = <FlSpot>[];
        final labels = <String>[];
        for (int i = 0; i < data.length; i++) {
          final w = (data[i]['weightKg'] ?? data[i]['weight'] ?? 0).toDouble();
          spots.add(FlSpot(i.toDouble(), w));
          labels.add(data[i]['date']?.toString().substring(0, 7) ?? '');
        }
        final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 0.5;
        final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 0.5;
        return Container(
          height: 180,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2BB673).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2BB673).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  'Kilo Takibi',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF2BB673),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: (maxY - minY) / 4,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: Color(0x202BB673),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (v, _) => Text(
                            '${v.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: (spots.length / 4).ceilToDouble().clamp(1, 999),
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                            return Text(
                              labels[i].length >= 7 ? labels[i].substring(5) : labels[i],
                              style: const TextStyle(fontSize: 9),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xFF2BB673),
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                            radius: 3,
                            color: const Color(0xFF2BB673),
                            strokeWidth: 1.5,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF2BB673).withOpacity(0.1),
                        ),
                      ),
                    ],
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

// ── Add Record Dialog ──────────────────────────────────────────────────────

class _AddRecordDialog extends StatefulWidget {
  final String petId;

  const _AddRecordDialog({required this.petId});

  @override
  State<_AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<_AddRecordDialog> {
  String _type = 'weight';
  DateTime _date = DateTime.now();
  final _weightCtrl = TextEditingController();
  final _medNameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _vetNameCtrl = TextEditingController();
  final _diagCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose();
    _medNameCtrl.dispose();
    _dosageCtrl.dispose();
    _freqCtrl.dispose();
    _vetNameCtrl.dispose();
    _diagCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final body = <String, dynamic>{
      'type': _type,
      'date': _date.toIso8601String(),
    };

    switch (_type) {
      case 'weight':
        final w = double.tryParse(_weightCtrl.text.trim());
        if (w == null || w <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Geçerli bir kilo girin.')));
          return;
        }
        body['weightKg'] = w;
        break;
      case 'medication':
        if (_medNameCtrl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('İlaç adı zorunludur.')));
          return;
        }
        body['medicationName'] = _medNameCtrl.text.trim();
        if (_dosageCtrl.text.trim().isNotEmpty) body['dosage'] = _dosageCtrl.text.trim();
        if (_freqCtrl.text.trim().isNotEmpty) body['frequency'] = _freqCtrl.text.trim();
        break;
      case 'vet_visit':
        if (_vetNameCtrl.text.trim().isNotEmpty) body['vetName'] = _vetNameCtrl.text.trim();
        if (_diagCtrl.text.trim().isNotEmpty) body['diagnosis'] = _diagCtrl.text.trim();
        break;
    }
    if (_notesCtrl.text.trim().isNotEmpty) body['notes'] = _notesCtrl.text.trim();

    Navigator.pop(context, body);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'tr');

    return AlertDialog(
      title: const Text('Sağlık Kaydı Ekle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Kayıt Tipi'),
              items: _typeLabels.entries.map((e) {
                return DropdownMenuItem(
                    value: e.key,
                    child: Row(children: [
                      Icon(_typeIcons[e.key]!, size: 18),
                      const SizedBox(width: 8),
                      Text(e.value),
                    ]));
              }).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            // Date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(fmt.format(_date)),
              subtitle: const Text('Kayıt tarihi'),
              onTap: _pickDate,
            ),
            const Divider(),
            // Type-specific fields
            if (_type == 'weight')
              TextField(
                controller: _weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Kilo (kg)',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
              ),
            if (_type == 'medication') ...[
              TextField(
                controller: _medNameCtrl,
                decoration: const InputDecoration(labelText: 'İlaç Adı *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _dosageCtrl,
                decoration:
                    const InputDecoration(labelText: 'Dozaj (ör. 5mg)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _freqCtrl,
                decoration: const InputDecoration(
                    labelText: 'Sıklık (ör. Günde 2 kez)'),
              ),
            ],
            if (_type == 'vet_visit') ...[
              TextField(
                controller: _vetNameCtrl,
                decoration: const InputDecoration(labelText: 'Veteriner Adı'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _diagCtrl,
                decoration: const InputDecoration(labelText: 'Tanı / Tedavi'),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Notlar (isteğe bağlı)',
                  alignLabelWithHint: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
        FilledButton(onPressed: _submit, child: const Text('Kaydet')),
      ],
    );
  }
}
