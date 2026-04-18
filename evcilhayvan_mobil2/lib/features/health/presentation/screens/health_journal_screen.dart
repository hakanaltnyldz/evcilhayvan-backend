// lib/features/health/presentation/screens/health_journal_screen.dart
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evcilhayvan_mobil2/features/health/data/repositories/health_repository.dart';
import 'package:evcilhayvan_mobil2/features/health/domain/models/health_record_model.dart';
import 'package:evcilhayvan_mobil2/core/widgets/animated_empty_state.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';


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

final _petFeedingProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, petId) async {
    final r = await ApiClient().dio.get('/api/pets/$petId');
    final pet = Map<String, dynamic>.from(r.data as Map);
    return pet;
  },
);

// ── Helpers ────────────────────────────────────────────────────────────────

const _typeIcons = {
  'weight': Icons.monitor_weight_outlined,
  'medication': Icons.medication_outlined,
  'vet_visit': Icons.local_hospital_outlined,
  'note': Icons.notes_rounded,
};

const _typeColors = {
  'weight': Color(0xFF2D6A4F),
  'medication': Color(0xFF52B788),
  'vet_visit': Color(0xFF40916C),
  'note': Color(0xFF74C69D),
};

String _typeLabel(String type, AppLocalizations l10n) {
  switch (type) {
    case 'weight':
      return l10n.healthTypeWeight;
    case 'medication':
      return l10n.healthTypeMedication;
    case 'vet_visit':
      return l10n.healthTypeVetVisit;
    case 'note':
      return l10n.healthTypeNote;
    default:
      return type;
  }
}

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

class _HealthJournalScreenState extends ConsumerState<HealthJournalScreen>
    with SingleTickerProviderStateMixin {
  String? _filterType;
  final _fmt = DateFormat('dd MMM yyyy', 'tr');
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
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.healthRecordAdded)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  Future<void> _delete(String recordId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.healthRecordDeleteTitle),
        content: Text(l10n.healthRecordDeleteContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.delete)),
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
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.healthJournalTitle(widget.petName)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.medical_information), text: 'Sağlık Kayıtları'),
            Tab(icon: Icon(Icons.restaurant), text: 'Beslenme'),
          ],
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (_, __) => _tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: _addRecord,
                icon: const Icon(Icons.add),
                label: Text(l10n.healthAddRecord),
              )
            : FloatingActionButton.extended(
                onPressed: () => _showAddMealSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Öğün Ekle'),
                backgroundColor: const Color(0xFF40916C),
              ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RecordsTab(
            petId: widget.petId,
            filterType: _filterType,
            onFilterChanged: (t) => setState(() => _filterType = t),
            fmt: _fmt,
            onAddRecord: _addRecord,
            onDelete: _delete,
          ),
          _FeedingTab(petId: widget.petId),
        ],
      ),
    );
  }

  Future<void> _showAddMealSheet(BuildContext context) async {
    final timeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final foodCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Öğün Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: timeCtrl,
              decoration: const InputDecoration(labelText: 'Saat (ör: 08:00)', prefixIcon: Icon(Icons.access_time)),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Miktar (ör: 100g)', prefixIcon: Icon(Icons.scale)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: foodCtrl,
              decoration: const InputDecoration(labelText: 'Mama Türü (ör: Kuru Mama)', prefixIcon: Icon(Icons.pets)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final petAsync = ref.read(_petFeedingProvider(widget.petId));
                  final existing = (petAsync.valueOrNull?['feedingSchedule'] as List? ?? [])
                      .cast<Map<String, dynamic>>();
                  final updated = [...existing, {
                    'time': timeCtrl.text.trim(),
                    'amount': amountCtrl.text.trim(),
                    'foodType': foodCtrl.text.trim(),
                  }];
                  await ApiClient().dio.patch('/api/pets/${widget.petId}/feeding', data: {
                    'feedingSchedule': updated,
                  });
                  ref.invalidate(_petFeedingProvider(widget.petId));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Öğün eklendi')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

}

// ── Sağlık Kayıtları Sekmesi ────────────────────────────────────────────────

class _RecordsTab extends ConsumerWidget {
  final String petId;
  final String? filterType;
  final ValueChanged<String?> onFilterChanged;
  final DateFormat fmt;
  final VoidCallback onAddRecord;
  final Future<void> Function(String) onDelete;

  const _RecordsTab({
    required this.petId,
    required this.filterType,
    required this.onFilterChanged,
    required this.fmt,
    required this.onAddRecord,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recordsAsync = ref.watch(healthRecordsProvider(petId));

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: Text(l10n.healthTypeAll),
                selected: filterType == null,
                onSelected: (_) => onFilterChanged(null),
              ),
              const SizedBox(width: 8),
              ...['weight', 'medication', 'vet_visit', 'note'].map((t) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_typeLabel(t, l10n)),
                    selected: filterType == t,
                    avatar: Icon(_typeIcons[t]!, size: 16),
                    onSelected: (_) => onFilterChanged(filterType == t ? null : t),
                  ),
                );
              }),
            ],
          ),
        ),
        const Divider(height: 1),
        if (filterType == 'weight') _WeightChartSection(petId: petId),
        Expanded(
          child: recordsAsync.when(
            loading: () => const Center(child: PawLoading()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(l10n.healthLoadError(e.toString())),
                  TextButton(
                    onPressed: () => ref.invalidate(healthRecordsProvider(petId)),
                    child: Text(l10n.healthRefresh),
                  ),
                ],
              ),
            ),
            data: (records) {
              final filtered = filterType == null
                  ? records
                  : records.where((r) => r.type == filterType).toList();
              if (filtered.isEmpty) {
                return AnimatedEmptyState(
                  icon: Icons.health_and_safety_outlined,
                  title: filterType == null ? l10n.healthNoRecords : l10n.healthNoFilterRecords(filterType!),
                  subtitle: l10n.healthAddHint,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final record = filtered[index];
                  return _RecordCard(record: record, fmt: fmt, onDelete: () => onDelete(record.id));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Beslenme Sekmesi ────────────────────────────────────────────────────────

class _FeedingTab extends ConsumerWidget {
  final String petId;
  const _FeedingTab({required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(_petFeedingProvider(petId));

    return petAsync.when(
      loading: () => const Center(child: PawLoading()),
      error: (e, _) => Center(child: Text('Yüklenemedi: $e')),
      data: (petData) {
        final schedule = (petData['feedingSchedule'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        final currentWeight = (petData['currentWeight'] as num?)?.toDouble();
        final targetWeight = (petData['targetWeight'] as num?)?.toDouble();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Kilo kartı
            _WeightCard(
              petId: petId,
              currentWeight: currentWeight,
              targetWeight: targetWeight,
              onUpdated: () => ref.invalidate(_petFeedingProvider(petId)),
            ),
            const SizedBox(height: 16),
            // Öğünler başlığı
            Row(
              children: [
                const Icon(Icons.restaurant, size: 18, color: Color(0xFF2D6A4F)),
                const SizedBox(width: 8),
                const Text('Beslenme Takvimi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Text('${schedule.length} öğün', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            if (schedule.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.no_meals, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Henüz öğün eklenmedi', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              ...schedule.asMap().entries.map((e) {
                final i = e.key;
                final meal = e.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD8F3DC), shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restaurant, size: 20, color: Color(0xFF2D6A4F)),
                    ),
                    title: Text(meal['time']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${meal['amount'] ?? ''} • ${meal['foodType'] ?? ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () async {
                        final updated = [...schedule]..removeAt(i);
                        try {
                          await ApiClient().dio.patch('/api/pets/$petId/feeding', data: {
                            'feedingSchedule': updated,
                          });
                          ref.invalidate(_petFeedingProvider(petId));
                        } catch (_) {}
                      },
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _WeightCard extends ConsumerStatefulWidget {
  final String petId;
  final double? currentWeight;
  final double? targetWeight;
  final VoidCallback onUpdated;
  const _WeightCard({required this.petId, this.currentWeight, this.targetWeight, required this.onUpdated});

  @override
  ConsumerState<_WeightCard> createState() => _WeightCardState();
}

class _WeightCardState extends ConsumerState<_WeightCard> {
  bool _editing = false;
  late TextEditingController _curCtrl;
  late TextEditingController _tgtCtrl;

  @override
  void initState() {
    super.initState();
    _curCtrl = TextEditingController(text: widget.currentWeight?.toString() ?? '');
    _tgtCtrl = TextEditingController(text: widget.targetWeight?.toString() ?? '');
  }

  @override
  void dispose() {
    _curCtrl.dispose();
    _tgtCtrl.dispose();
    super.dispose();
  }

  double? get _progress {
    final cur = widget.currentWeight;
    final tgt = widget.targetWeight;
    if (cur == null || tgt == null || tgt == 0) return null;
    return (cur / tgt).clamp(0.0, 1.5);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_weight, color: Color(0xFF2D6A4F)),
                const SizedBox(width: 8),
                const Text('Kilo Takibi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                IconButton(
                  icon: Icon(_editing ? Icons.check : Icons.edit, size: 20),
                  onPressed: () async {
                    if (_editing) {
                      try {
                        await ApiClient().dio.patch('/api/pets/${widget.petId}/feeding', data: {
                          if (_curCtrl.text.isNotEmpty) 'currentWeight': double.tryParse(_curCtrl.text),
                          if (_tgtCtrl.text.isNotEmpty) 'targetWeight': double.tryParse(_tgtCtrl.text),
                        });
                        widget.onUpdated();
                      } catch (_) {}
                    }
                    setState(() => _editing = !_editing);
                  },
                ),
              ],
            ),
            if (_editing) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _curCtrl,
                      decoration: const InputDecoration(labelText: 'Mevcut Kilo (kg)', isDense: true),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _tgtCtrl,
                      decoration: const InputDecoration(labelText: 'Hedef Kilo (kg)', isDense: true),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Mevcut: ${widget.currentWeight != null ? "${widget.currentWeight} kg" : "—"}',
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 16),
                  Text('Hedef: ${widget.targetWeight != null ? "${widget.targetWeight} kg" : "—"}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  color: progress > 1.0 ? Colors.orange : const Color(0xFF52B788),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% hedefe ulaşıldı',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ],
        ),
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
    final l10n = AppLocalizations.of(context)!;
    final color = _typeColors[record.type] ?? const Color(0xFF2D6A4F);
    final icon = _typeIcons[record.type] ?? Icons.notes_rounded;
    final label = _typeLabel(record.type, l10n);

    List<String> details = [];
    if (record.type == 'weight' && record.weightKg != null) {
      details.add('${record.weightKg!.toStringAsFixed(1)} kg');
    }
    if (record.type == 'medication') {
      if (record.medicationName != null) details.add(record.medicationName!);
      if (record.dosage != null) details.add(l10n.healthDose(record.dosage!));
      if (record.frequency != null) details.add(l10n.healthFrequency(record.frequency!));
    }
    if (record.type == 'vet_visit') {
      if (record.vetName != null) details.add(l10n.healthVetName(record.vetName!));
      if (record.diagnosis != null) details.add(l10n.healthDiagnosis(record.diagnosis!));
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

class _WeightChartSection extends ConsumerStatefulWidget {
  final String petId;
  const _WeightChartSection({required this.petId});

  @override
  ConsumerState<_WeightChartSection> createState() => _WeightChartSectionState();
}

class _WeightChartSectionState extends ConsumerState<_WeightChartSection> {
  double? _goalWeight;
  static const _chartColor = Color(0xFF2D6A4F);

  @override
  void initState() {
    super.initState();
    _loadGoalWeight();
  }

  Future<void> _loadGoalWeight() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getDouble('goal_weight_${widget.petId}');
    if (mounted) setState(() => _goalWeight = val);
  }

  Future<void> _editGoalWeight(List<FlSpot> spots) async {
    final ctrl = TextEditingController(
      text: _goalWeight != null ? _goalWeight!.toStringAsFixed(1) : '',
    );
    final result = await showDialog<double?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hedef Ağırlık'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Hedef ağırlık (kg)',
            suffixText: 'kg',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          if (_goalWeight != null)
            TextButton(
              onPressed: () => Navigator.pop(context, -1),
              child: const Text('Kaldır', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
              Navigator.pop(context, v);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (result < 0) {
      await prefs.remove('goal_weight_${widget.petId}');
      setState(() => _goalWeight = null);
    } else {
      await prefs.setDouble('goal_weight_${widget.petId}', result);
      setState(() => _goalWeight = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chartAsync = ref.watch(weightChartProvider(widget.petId));
    return chartAsync.when(
      loading: () => const SizedBox(
        height: 160,
        child: Center(child: PawLoading()),
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
                l10n.healthWeightChartError,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(weightChartProvider(widget.petId)),
              child: Text(l10n.healthRefresh),
            ),
          ],
        ),
      ),
      data: (data) {
        if (data.length < 2) return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: _chartColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _chartColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.show_chart, color: _chartColor.withOpacity(0.5), size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.healthWeightChart,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _chartColor, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(l10n.healthWeightChartMin,
                    style: Theme.of(context).textTheme.bodySmall),
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
        final weights = spots.map((s) => s.y).toList();
        final minW = weights.reduce(math.min);
        final maxW = weights.reduce(math.max);
        final avg = weights.reduce((a, b) => a + b) / weights.length;
        final trend = weights.length >= 2
            ? (weights.last > weights[weights.length - 2]
                ? '↑'
                : weights.last < weights[weights.length - 2]
                    ? '↓'
                    : '→')
            : '→';

        final allValues = [...weights];
        if (_goalWeight != null) allValues.add(_goalWeight!);
        final minY = allValues.reduce(math.min) - 1;
        final maxY = allValues.reduce(math.max) + 1;

        return Column(
          children: [
            // Stats row
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _chartColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _chartColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip('Ort.', '${avg.toStringAsFixed(1)} kg'),
                  _StatChip('Min', '${minW.toStringAsFixed(1)} kg'),
                  _StatChip('Maks', '${maxW.toStringAsFixed(1)} kg'),
                  _StatChip('Trend', trend),
                ],
              ),
            ),

            // Chart
            Container(
              height: 200,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: BoxDecoration(
                color: _chartColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _chartColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(l10n.healthWeightChart,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _chartColor, fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _editGoalWeight(spots),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Icon(Icons.flag_outlined, size: 14, color: _goalWeight != null ? Colors.red : Colors.grey),
                              const SizedBox(width: 2),
                              Text(
                                _goalWeight != null ? '${_goalWeight!.toStringAsFixed(1)} kg hedef' : 'Hedef ekle',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _goalWeight != null ? Colors.red : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                        extraLinesData: _goalWeight != null
                            ? ExtraLinesData(horizontalLines: [
                                HorizontalLine(
                                  y: _goalWeight!,
                                  color: Colors.red.withOpacity(0.6),
                                  strokeWidth: 1.5,
                                  dashArray: [6, 4],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.only(right: 4, bottom: 2),
                                    style: const TextStyle(fontSize: 10, color: Colors.red),
                                    labelResolver: (_) => 'Hedef',
                                  ),
                                ),
                              ])
                            : null,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (v, _) => Text(
                                v.toStringAsFixed(1),
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
                            color: _chartColor,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, _, __, index) => FlDotCirclePainter(
                                radius: index == spots.length - 1 ? 5 : 3,
                                color: _chartColor,
                                strokeWidth: 1.5,
                                strokeColor: Colors.white,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: _chartColor.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))),
        Text(label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
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
    final l10n = AppLocalizations.of(context)!;
    final body = <String, dynamic>{
      'type': _type,
      'date': _date.toIso8601String(),
    };

    switch (_type) {
      case 'weight':
        final w = double.tryParse(_weightCtrl.text.trim());
        if (w == null || w <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.healthErrWeight)));
          return;
        }
        body['weightKg'] = w;
        break;
      case 'medication':
        if (_medNameCtrl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.healthErrMedName)));
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
    final l10n = AppLocalizations.of(context)!;
    final fmt = DateFormat('dd MMM yyyy', 'tr');

    return AlertDialog(
      title: Text(l10n.healthAddDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(labelText: l10n.healthRecordType),
              items: ['weight', 'medication', 'vet_visit', 'note'].map((t) {
                return DropdownMenuItem(
                    value: t,
                    child: Row(children: [
                      Icon(_typeIcons[t]!, size: 18),
                      const SizedBox(width: 8),
                      Text(_typeLabel(t, l10n)),
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
              subtitle: Text(l10n.healthRecordDate),
              onTap: _pickDate,
            ),
            const Divider(),
            // Type-specific fields
            if (_type == 'weight')
              TextField(
                controller: _weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.healthWeightKg,
                  prefixIcon: const Icon(Icons.monitor_weight_outlined),
                ),
              ),
            if (_type == 'medication') ...[
              TextField(
                controller: _medNameCtrl,
                decoration: InputDecoration(labelText: l10n.healthMedName),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _dosageCtrl,
                decoration: InputDecoration(labelText: l10n.healthMedDosage),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _freqCtrl,
                decoration: InputDecoration(labelText: l10n.healthMedFreq),
              ),
            ],
            if (_type == 'vet_visit') ...[
              TextField(
                controller: _vetNameCtrl,
                decoration: InputDecoration(labelText: l10n.healthVetNameLabel),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _diagCtrl,
                decoration: InputDecoration(labelText: l10n.healthDiagnosisTreatment),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                  labelText: l10n.healthNotes,
                  alignLabelWithHint: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
