import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:evcilhayvan_mobil2/core/widgets/premium_card.dart';
import 'package:evcilhayvan_mobil2/core/widgets/interactive_scale.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/core/widgets/step_progress.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';
import '../../data/repositories/pet_sitter_repository.dart';
import '../../domain/models/pet_sitter_model.dart';

class SitterBookingScreen extends ConsumerStatefulWidget {
  final PetSitterModel sitter;
  const SitterBookingScreen({super.key, required this.sitter});

  @override
  ConsumerState<SitterBookingScreen> createState() => _SitterBookingScreenState();
}

class _SitterBookingScreenState extends ConsumerState<SitterBookingScreen> {
  int _step = 0;
  String? _selectedServiceType;
  String? _selectedPetId;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1, hours: 2));
  final _notesController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ── Business logic (unchanged) ──────────────────────────────────

  double _calcPrice() {
    if (_selectedServiceType == null) return 0;
    final service = widget.sitter.services.firstWhere(
      (s) => s.type == _selectedServiceType,
      orElse: () => SitterService(type: ''),
    );
    if (service.type.isEmpty) return 0;
    final hours = _endDate.difference(_startDate).inHours.abs();
    final days = (_endDate.difference(_startDate).inHours / 24).ceil();
    if (service.pricePerDay > 0 && days >= 1) return service.pricePerDay * days;
    return service.pricePerHour * hours;
  }

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() => _startDate = DateTime(d.year, d.month, d.day, _startDate.hour, _startDate.minute));
    }
  }

  Future<void> _pickEndDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() => _endDate = DateTime(d.year, d.month, d.day, _endDate.hour, _endDate.minute));
    }
  }

  Future<void> _submit() async {
    if (_selectedServiceType == null) { _snack('Hizmet secin'); return; }
    if (_selectedPetId == null) { _snack('Pet secin'); return; }
    if (_endDate.isBefore(_startDate)) { _snack('Bitis tarihi baslangictan once olamaz'); return; }

    setState(() => _loading = true);
    try {
      await ref.read(petSitterRepositoryProvider).createBooking({
        'sitterId': widget.sitter.id,
        'petId': _selectedPetId,
        'serviceType': _selectedServiceType,
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
        'notes': _notesController.text.trim(),
      });

      if (mounted) {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8F3DC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.check_circle, color: Color(0xFF2D6A4F), size: 36),
                ),
                const SizedBox(height: 16),
                const Text('Rezervasyon Gönderildi!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(
                  'Bakıcınız rezervasyon talebinizi inceleyecek.',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Tamam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  // ── Navigation helpers ──────────────────────────────────────────

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _selectedServiceType != null;
      case 1:
        return _selectedPetId != null;
      case 2:
        return !_endDate.isBefore(_startDate);
      default:
        return true;
    }
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

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

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text('${widget.sitter.displayName} - Rezervasyon'),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          StepProgress(
            totalSteps: 4,
            currentStep: _step,
            stepLabels: const ['Hizmet', 'Pet', 'Tarih', 'Özet'],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: _buildStep(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildServiceStep();
      case 1:
        return _buildPetStep();
      case 2:
        return _buildDateStep();
      case 3:
        return _buildSummaryStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0: Service Selection ───────────────────────────────────

  Widget _buildServiceStep() {
    final services = widget.sitter.services;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final s = services[index];
        final selected = _selectedServiceType == s.type;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InteractiveScale(
            onTap: () => setState(() => _selectedServiceType = s.type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? const Color(0xFF52B788) : context.subtleBorder,
                  width: selected ? 2 : 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D6A4F).withOpacity(context.isDark ? 0.12 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF52B788).withOpacity(0.15)
                                : context.subtleBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _serviceIcon(s.type),
                            color: selected ? const Color(0xFF2D6A4F) : Colors.grey.shade500,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: context.onCard,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (s.pricePerHour > 0)
                                    _priceTag('${s.pricePerHour.toInt()} TL/saat'),
                                  if (s.pricePerHour > 0 && s.pricePerDay > 0)
                                    const SizedBox(width: 8),
                                  if (s.pricePerDay > 0)
                                    _priceTag('${s.pricePerDay.toInt()} TL/gün'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFF52B788),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms, delay: (index * 80).ms).slideX(begin: 0.05, end: 0),
        );
      },
    );
  }

  Widget _priceTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F3DC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D6A4F),
        ),
      ),
    );
  }

  // ── Step 1: Pet Selection ───────────────────────────────────────

  Widget _buildPetStep() {
    final petsAsync = ref.watch(myPetsProvider);
    return petsAsync.when(
      loading: () => Center(child: PawLoading.fullScreen()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Petler yüklenemedi: $e', style: TextStyle(color: Colors.red.shade400)),
        ),
      ),
      data: (pets) {
        if (pets.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz petiniz yok.\nÖnce pet ekleyin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.secondaryText, fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.85,
          ),
          itemCount: pets.length,
          itemBuilder: (context, index) {
            final pet = pets[index];
            final selected = _selectedPetId == pet.id;
            final photoUrl = pet.photos.isNotEmpty ? pet.photos.first : null;
            final fullUrl = photoUrl != null
                ? (photoUrl.startsWith('http') ? photoUrl : '$apiBaseUrl$photoUrl')
                : null;

            return InteractiveScale(
              onTap: () => setState(() => _selectedPetId = pet.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? const Color(0xFF52B788) : context.subtleBorder,
                    width: selected ? 2 : 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D6A4F).withOpacity(context.isDark ? 0.12 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: fullUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: fullUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: context.subtleBackground,
                                        child: const Icon(Icons.pets, color: Color(0xFF95D5B2), size: 32),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: context.subtleBackground,
                                        child: const Icon(Icons.pets, color: Color(0xFF95D5B2), size: 32),
                                      ),
                                    )
                                  : Container(
                                      color: context.subtleBackground,
                                      child: const Icon(Icons.pets, color: Color(0xFF95D5B2), size: 32),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            pet.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: context.onCard,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pet.species,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFF52B788),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: (index * 80).ms).scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1));
          },
        );
      },
    );
  }

  // ── Step 2: Date Range Selection ────────────────────────────────

  Widget _buildDateStep() {
    final diff = _endDate.difference(_startDate);
    final days = diff.inDays;
    final hours = diff.inHours;
    final durationText = days >= 1 ? '$days gün' : '$hours saat';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PremiumCard(
                  onTap: _pickStartDate,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF52B788).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.calendar_today, color: Color(0xFF2D6A4F), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Başlangıç',
                              style: TextStyle(fontSize: 11, color: context.secondaryText),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fmt(_startDate),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: context.onCard,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PremiumCard(
                  onTap: _pickEndDate,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF52B788).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.calendar_today, color: Color(0xFF2D6A4F), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bitiş',
                              style: TextStyle(fontSize: 11, color: context.secondaryText),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fmt(_endDate),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: context.onCard,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFD8F3DC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, color: Color(0xFF2D6A4F), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Toplam süre: $durationText',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D6A4F),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
        ],
      ),
    );
  }

  // ── Step 3: Summary + Notes + Submit ────────────────────────────

  Widget _buildSummaryStep() {
    final petsAsync = ref.watch(myPetsProvider);
    final selectedService = _selectedServiceType != null
        ? widget.sitter.services.firstWhere(
            (s) => s.type == _selectedServiceType,
            orElse: () => SitterService(type: ''),
          )
        : null;

    String petName = '';
    petsAsync.whenData((pets) {
      final match = pets.where((p) => p.id == _selectedPetId);
      if (match.isNotEmpty) petName = match.first.name;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Notes
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notlar (opsiyonel)',
              hintText: 'Özel istekleriniz varsa buraya yazabilirsiniz...',
              filled: true,
              fillColor: context.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.note_alt_outlined, color: Color(0xFF52B788)),
            ),
            maxLines: 3,
          ).animate().fadeIn(duration: 350.ms),
          const SizedBox(height: 20),

          // Price summary card
          PremiumCard(
            accentColor: const Color(0xFF52B788),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rezervasyon Özeti',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: context.onCard,
                  ),
                ),
                const SizedBox(height: 16),
                _summaryRow(Icons.room_service, 'Hizmet', selectedService?.label ?? '-'),
                const SizedBox(height: 10),
                _summaryRow(Icons.pets, 'Pet', petName.isNotEmpty ? petName : '-'),
                const SizedBox(height: 10),
                _summaryRow(
                  Icons.date_range,
                  'Tarih',
                  '${_fmt(_startDate)} - ${_fmt(_endDate)}',
                ),
                const SizedBox(height: 10),
                _summaryRow(Icons.person, 'Bakıcı', widget.sitter.displayName),
                const Divider(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tahmini Toplam',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: context.onCard,
                      ),
                    ),
                    Text(
                      '${_calcPrice().toInt()} TL',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color(0xFF2D6A4F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, end: 0),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF52B788)),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: TextStyle(fontSize: 13, color: context.secondaryText),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: context.onCard,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  // ── Bottom Navigation Bar ───────────────────────────────────────

  Widget _buildBottomBar() {
    final isLast = _step == 3;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(top: BorderSide(color: context.subtleBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _back,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D6A4F),
                    side: const BorderSide(color: Color(0xFF52B788)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Geri', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            flex: _step == 0 ? 1 : 1,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _canProceed ? (isLast ? (_loading ? null : _submit) : _next) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isLast ? 'Gönder' : 'Devam',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
