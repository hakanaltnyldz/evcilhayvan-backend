import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';


import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import '../../data/repositories/vaccination_repository.dart';
import '../../domain/models/vaccination_schedule_model.dart';

class VaccinationCalendarScreen extends ConsumerStatefulWidget {
  final String petId;
  const VaccinationCalendarScreen({super.key, required this.petId});

  @override
  ConsumerState<VaccinationCalendarScreen> createState() => _VaccinationCalendarScreenState();
}

class _VaccinationCalendarScreenState extends ConsumerState<VaccinationCalendarScreen> {
  bool _showCalendar = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(petVaccinationCalendarProvider(widget.petId));

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: Text(l10n.vacCalendarTitle),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Görünüm toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true,  icon: Icon(Icons.calendar_month, size: 18)),
                ButtonSegment(value: false, icon: Icon(Icons.list, size: 18)),
              ],
              selected: {_showCalendar},
              onSelectionChanged: (s) => setState(() => _showCalendar = s.first),
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.pushNamed('vaccination-add', pathParameters: {'petId': widget.petId}),
          ),
        ],
      ),
      body: calendarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.vacCalendarLoadErr(e.toString()))),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.vaccines, size: 64, color: Colors.grey.shade600.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(l10n.vacCalendarEmpty),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.pushNamed('vaccination-add', pathParameters: {'petId': widget.petId}),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.vacCalendarAddRecord),
                  ),
                ],
              ),
            );
          }

          // Takvim event haritası oluştur: tarih → item listesi
          final eventMap = <DateTime, List<VaccinationCalendarItem>>{};
          for (final item in items) {
            if (item.nextDueDate != null) {
              final d = _dayOnly(item.nextDueDate!);
              eventMap[d] = [...(eventMap[d] ?? []), item];
            }
            for (final r in item.records) {
              final d = _dayOnly(r.dateAdministered);
              eventMap[d] = [...(eventMap[d] ?? []), item];
            }
          }

          if (_showCalendar) {
            return _buildCalendarView(items, eventMap, context);
          } else {
            return _buildListView(items, context);
          }
        },
      ),
    );
  }

  DateTime _dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Widget _buildCalendarView(
    List<VaccinationCalendarItem> items,
    Map<DateTime, List<VaccinationCalendarItem>> eventMap,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final selectedItems = _selectedDay != null
        ? (eventMap[_dayOnly(_selectedDay!)] ?? [])
        : <VaccinationCalendarItem>[];

    return Column(
      children: [
        TableCalendar<VaccinationCalendarItem>(
          locale: 'tr_TR',
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 730)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => _selectedDay != null && isSameDay(_selectedDay!, day),
          eventLoader: (day) => eventMap[_dayOnly(day)] ?? [],
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Ay'},
          startingDayOfWeek: StartingDayOfWeek.monday,
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          onPageChanged: (focused) => setState(() => _focusedDay = focused),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: const Color(0xFF2D6A4F).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: const Color(0xFF2D6A4F),
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            markerSize: 6,
            markersMaxCount: 3,
            outsideDaysVisible: false,
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return const SizedBox.shrink();
              // Renk önceliği: overdue > due_soon > upcoming > completed
              final colors = events.map((e) => _statusColor(e.status)).toList();
              return Positioned(
                bottom: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: colors.take(3).map((c) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  )).toList(),
                ),
              );
            },
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        const Divider(height: 1),

        // Seçili gün detayları
        Expanded(
          child: selectedItems.isEmpty
              ? Center(
                  child: Text(
                    _selectedDay != null ? AppLocalizations.of(context)!.vacCalendarNoRecord : AppLocalizations.of(context)!.vacCalendarClickDay,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: selectedItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = selectedItems[i];
                    return _VaccinationEventTile(item: item, petId: widget.petId);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildListView(List<VaccinationCalendarItem> items, BuildContext context) {
    final sorted = List<VaccinationCalendarItem>.from(items)
      ..sort((a, b) => _statusPriority(a.status).compareTo(_statusPriority(b.status)));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(petVaccinationCalendarProvider(widget.petId)),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          return _VaccinationCalendarCard(item: sorted[index], petId: widget.petId);
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'overdue':    return Colors.red;
      case 'due_soon':   return Colors.orange;
      case 'completed':  return const Color(0xFF52B788);
      case 'upcoming':   return const Color(0xFF52B788);
      default:           return Colors.grey;
    }
  }

  int _statusPriority(String status) {
    switch (status) {
      case 'overdue':    return 0;
      case 'due_soon':   return 1;
      case 'upcoming':   return 2;
      case 'not_started':return 3;
      case 'completed':  return 4;
      default:           return 5;
    }
  }
}

// ─── Takvim görünümü için kompakt tile ──────────────────────────────────────

class _VaccinationEventTile extends StatelessWidget {
  final VaccinationCalendarItem item;
  final String petId;

  const _VaccinationEventTile({required this.item, required this.petId});

  Color get _color {
    switch (item.status) {
      case 'overdue':   return Colors.red;
      case 'due_soon':  return Colors.orange;
      case 'completed': return const Color(0xFF52B788);
      case 'upcoming':  return const Color(0xFF52B788);
      default:          return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _color.withOpacity(0.15),
          child: Icon(Icons.vaccines, color: _color, size: 20),
        ),
        title: Text(item.schedule.vaccineName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(item.statusText),
        trailing: item.status != 'completed'
            ? TextButton(
                onPressed: () => context.pushNamed(
                  'vaccination-add',
                  pathParameters: {'petId': petId},
                ),
                child: Text(AppLocalizations.of(context)!.vacCalendarAdd),
              )
            : const Icon(Icons.check_circle, color: Color(0xFF52B788)),
      ),
    );
  }
}

// ─── Liste görünümü kartı (eskisi korundu) ───────────────────────────────────

class _VaccinationCalendarCard extends StatelessWidget {
  final VaccinationCalendarItem item;
  final String petId;

  const _VaccinationCalendarCard({required this.item, required this.petId});

  Color get _color {
    switch (item.status) {
      case 'overdue':   return Colors.red;
      case 'due_soon':  return Colors.orange;
      case 'completed': return const Color(0xFF52B788);
      case 'upcoming':  return const Color(0xFF52B788);
      default:          return Colors.grey.shade600;
    }
  }

  IconData get _icon {
    switch (item.status) {
      case 'overdue':   return Icons.warning;
      case 'due_soon':  return Icons.schedule;
      case 'completed': return Icons.check_circle;
      case 'upcoming':  return Icons.event;
      default:          return Icons.vaccines;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final schedule = item.schedule;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_icon, color: _color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(schedule.vaccineName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      if (schedule.description != null)
                        Text(schedule.description!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item.statusText, style: theme.textTheme.labelSmall?.copyWith(color: _color, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    _infoChip(l10n.vacCalendarFirstDose(schedule.firstDoseMonths), Icons.calendar_month, theme),
                    if (schedule.repeatIntervalMonths != null)
                      _infoChip(l10n.vacCalendarRepeat(schedule.repeatIntervalMonths!), Icons.repeat, theme),
                    if (schedule.isRequired)
                      _infoChip(l10n.vacCalendarRequired, Icons.priority_high, theme, color: Colors.red),
                  ],
                ),
                if (item.nextDueDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.event_note, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        l10n.vacCalendarNext('${item.nextDueDate!.day}.${item.nextDueDate!.month}.${item.nextDueDate!.year}'),
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
                if (item.records.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...item.records.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check, size: 14, color: Color(0xFF52B788)),
                            const SizedBox(width: 6),
                            Text(
                              '${r.dateAdministered.day}.${r.dateAdministered.month}.${r.dateAdministered.year}',
                              style: theme.textTheme.bodySmall,
                            ),
                            if (r.notes != null) ...[
                              const SizedBox(width: 8),
                              Expanded(child: Text(r.notes!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
                            ],
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String text, IconData icon, ThemeData theme, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text, style: theme.textTheme.labelSmall?.copyWith(color: color ?? Colors.grey.shade600)),
        ],
      ),
    );
  }
}
