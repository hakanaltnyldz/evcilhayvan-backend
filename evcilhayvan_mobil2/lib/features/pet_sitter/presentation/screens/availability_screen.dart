// lib/features/pet_sitter/presentation/screens/availability_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import '../../../pet_sitter/data/repositories/pet_sitter_repository.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  final String sitterId;

  const AvailabilityScreen({super.key, required this.sitterId});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  final Set<DateTime> _blockedDates = {};
  bool _loading = true;
  bool _saving = false;
  final Set<DateTime> _pendingAdd = {};
  final Set<DateTime> _pendingRemove = {};

  @override
  void initState() {
    super.initState();
    _loadBlockedDates();
  }

  Future<void> _loadBlockedDates() async {
    try {
      final repo = ref.read(petSitterRepositoryProvider);
      final sitterJson = await repo.getSitter(widget.sitterId);
      final raw = sitterJson['blockedDates'] as List?;
      if (mounted && raw != null) {
        setState(() {
          _blockedDates.clear();
          _blockedDates.addAll(
            raw.map((d) => DateTime.tryParse(d.toString())).whereType<DateTime>(),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Takvim yüklenemedi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isBlocked(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _blockedDates.any((b) => isSameDay(b, d));
  }

  void _toggleDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) return; // Geçmiş günler seçilemez

    setState(() {
      if (_isBlocked(d)) {
        _blockedDates.removeWhere((b) => isSameDay(b, d));
        _pendingRemove.add(d);
        _pendingAdd.remove(d);
      } else {
        _blockedDates.add(d);
        _pendingAdd.add(d);
        _pendingRemove.remove(d);
      }
    });
  }

  Future<void> _saveChanges() async {
    if (_pendingAdd.isEmpty && _pendingRemove.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Değişiklik yok')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final dio = ApiClient().dio;
      String fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      await dio.patch('/api/pet-sitters/${widget.sitterId}/blocked-dates', data: {
        'add': _pendingAdd.map(fmt).toList(),
        'remove': _pendingRemove.map(fmt).toList(),
      });

      if (mounted) {
        _pendingAdd.clear();
        _pendingRemove.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Müsaitlik takvimi kaydedildi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydetme başarısız: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Müsaitlik Takvimi'),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_pendingAdd.isNotEmpty || _pendingRemove.isNotEmpty)
            TextButton(
              onPressed: _saving ? null : _saveChanges,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Açıklama
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: isDark ? const Color(0xFF1E2E28) : const Color(0xFFD8F3DC),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppPalette.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Müsait olmadığınız günlere dokunun. Kırmızı günlerde rezervasyon alamazsınız.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: DateTime.now(),
                  locale: 'tr_TR',
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppPalette.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppPalette.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (ctx, day, focusedDay) {
                      if (_isBlocked(day)) {
                        return Container(
                          margin: const EdgeInsets.all(4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  onDaySelected: (selectedDay, focusedDay) => _toggleDay(selectedDay),
                ),

                const SizedBox(height: 16),

                // Legend
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _Legend(color: AppPalette.primary.withOpacity(0.3), label: 'Bugün'),
                      const SizedBox(width: 16),
                      _Legend(color: Colors.red.withOpacity(0.3), label: 'Müsait Değil'),
                      const SizedBox(width: 16),
                      _Legend(color: Colors.white, label: 'Müsait', border: true),
                    ],
                  ),
                ),

                if (_blockedDates.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${_blockedDates.length} gün bloke edildi',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool border;

  const _Legend({required this.color, required this.label, this.border = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: border ? Border.all(color: Colors.grey.shade400) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
