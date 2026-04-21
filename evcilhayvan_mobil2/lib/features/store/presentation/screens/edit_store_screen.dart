// lib/features/store/presentation/screens/edit_store_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/features/store/data/store_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/store_model.dart';

class EditStoreScreen extends ConsumerStatefulWidget {
  const EditStoreScreen({super.key, required this.store});

  final StoreModel store;

  @override
  ConsumerState<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends ConsumerState<EditStoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1 — Temel Bilgiler
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  // Tab 2 — İletişim
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _twitterCtrl;
  late final TextEditingController _facebookCtrl;

  // Tab 3 — Çalışma Saatleri
  late final TextEditingController _workingHoursCtrl;

  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _nameCtrl = TextEditingController(text: widget.store.name);
    _descCtrl = TextEditingController(text: widget.store.description ?? '');
    _phoneCtrl = TextEditingController(text: widget.store.phone ?? '');
    _websiteCtrl = TextEditingController(text: widget.store.website ?? '');
    _instagramCtrl = TextEditingController(text: widget.store.instagram ?? '');
    _twitterCtrl = TextEditingController(text: widget.store.twitter ?? '');
    _facebookCtrl = TextEditingController(text: widget.store.facebook ?? '');
    _workingHoursCtrl = TextEditingController(text: widget.store.workingHours ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _instagramCtrl.dispose();
    _twitterCtrl.dispose();
    _facebookCtrl.dispose();
    _workingHoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ApiClient().dio.patch('/api/stores/me/profile', data: {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'instagram': _instagramCtrl.text.trim(),
        'twitter': _twitterCtrl.text.trim(),
        'facebook': _facebookCtrl.text.trim(),
        'workingHours': _workingHoursCtrl.text.trim(),
      });

      ref.invalidate(myStoreProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mağaza profili güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Güncelleme başarısız: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mağazayı Düzenle', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: const TabBar(
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(icon: Icon(Icons.store_outlined, size: 18), text: 'Temel'),
            Tab(icon: Icon(Icons.contact_phone_outlined, size: 18), text: 'İletişim'),
            Tab(icon: Icon(Icons.schedule_outlined, size: 18), text: 'Saatler'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _BasicInfoTab(nameCtrl: _nameCtrl, descCtrl: _descCtrl),
            _ContactTab(
              phoneCtrl: _phoneCtrl,
              websiteCtrl: _websiteCtrl,
              instagramCtrl: _instagramCtrl,
              twitterCtrl: _twitterCtrl,
              facebookCtrl: _facebookCtrl,
            ),
            _WorkingHoursTab(ctrl: _workingHoursCtrl),
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: Temel Bilgiler ─────────────────────────────────────────────────────

class _BasicInfoTab extends StatelessWidget {
  const _BasicInfoTab({required this.nameCtrl, required this.descCtrl});

  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Mağaza Adı'),
          const SizedBox(height: 8),
          TextFormField(
            controller: nameCtrl,
            maxLength: 80,
            decoration: _inputDeco('Mağaza adınızı girin', context),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Mağaza adı zorunlu';
              if (v.trim().length < 2) return 'En az 2 karakter olmalı';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _SectionLabel('Açıklama'),
          const SizedBox(height: 8),
          TextFormField(
            controller: descCtrl,
            maxLines: 5,
            maxLength: 500,
            decoration: _inputDeco('Mağazanız hakkında kısa bir açıklama yazın', context),
          ),
          const SizedBox(height: 8),
          _InfoChip('Açıklama, mağaza profilinizde müşterilere gösterilir.'),
        ],
      ),
    );
  }
}

// ── Tab 2: İletişim ──────────────────────────────────────────────────────────

class _ContactTab extends StatelessWidget {
  const _ContactTab({
    required this.phoneCtrl,
    required this.websiteCtrl,
    required this.instagramCtrl,
    required this.twitterCtrl,
    required this.facebookCtrl,
  });

  final TextEditingController phoneCtrl;
  final TextEditingController websiteCtrl;
  final TextEditingController instagramCtrl;
  final TextEditingController twitterCtrl;
  final TextEditingController facebookCtrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Telefon'),
          const SizedBox(height: 8),
          TextFormField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 20,
            decoration: _inputDeco('0532 xxx xx xx', context,
                prefixIcon: Icons.phone_outlined),
          ),
          const SizedBox(height: 16),
          _SectionLabel('Web Sitesi'),
          const SizedBox(height: 8),
          TextFormField(
            controller: websiteCtrl,
            keyboardType: TextInputType.url,
            maxLength: 100,
            decoration: _inputDeco('https://www.maganiz.com', context,
                prefixIcon: Icons.language_outlined),
          ),
          const SizedBox(height: 16),
          _SectionLabel('Sosyal Medya'),
          const SizedBox(height: 8),
          _SocialField(
            ctrl: instagramCtrl,
            hint: 'Instagram kullanıcı adı',
            prefix: '@',
            icon: Icons.camera_alt_outlined,
            color: const Color(0xFFE1306C),
          ),
          const SizedBox(height: 10),
          _SocialField(
            ctrl: twitterCtrl,
            hint: 'Twitter/X kullanıcı adı',
            prefix: '@',
            icon: Icons.alternate_email,
            color: const Color(0xFF1DA1F2),
          ),
          const SizedBox(height: 10),
          _SocialField(
            ctrl: facebookCtrl,
            hint: 'Facebook sayfa adı',
            prefix: 'fb.com/',
            icon: Icons.facebook,
            color: const Color(0xFF1877F2),
          ),
        ],
      ),
    );
  }
}

class _SocialField extends StatelessWidget {
  const _SocialField({
    required this.ctrl,
    required this.hint,
    required this.prefix,
    required this.icon,
    required this.color,
  });

  final TextEditingController ctrl;
  final String hint;
  final String prefix;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      maxLength: 60,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        prefixIcon: Icon(icon, color: color, size: 20),
        prefixText: prefix,
        prefixStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: context.cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

// ── Tab 3: Çalışma Saatleri ───────────────────────────────────────────────────

class _WorkingHoursTab extends StatefulWidget {
  const _WorkingHoursTab({required this.ctrl});

  final TextEditingController ctrl;

  @override
  State<_WorkingHoursTab> createState() => _WorkingHoursTabState();
}

class _WorkingHoursTabState extends State<_WorkingHoursTab> {
  static const _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  // State: gün adı → açılış/kapanış (null = kapalı)
  final Map<String, TimeOfDay?> _open = {};
  final Map<String, TimeOfDay?> _close = {};
  final Map<String, bool> _enabled = {};

  @override
  void initState() {
    super.initState();
    _parseFromText(widget.ctrl.text);
  }

  void _parseFromText(String text) {
    // Basit init — hepsini 09:00-18:00 varsayılan yap
    for (final day in _days) {
      _enabled[day] = true;
      _open[day] = const TimeOfDay(hour: 9, minute: 0);
      _close[day] = const TimeOfDay(hour: 18, minute: 0);
    }
    // Pazartesi ve Pazar kapalı varsayılan
    _enabled['Cmt'] = false;
    _enabled['Paz'] = false;
  }

  String _buildText() {
    final parts = <String>[];
    for (final day in _days) {
      if (_enabled[day] == true && _open[day] != null && _close[day] != null) {
        final o = _open[day]!;
        final c = _close[day]!;
        parts.add(
          '$day ${o.hour.toString().padLeft(2, '0')}:${o.minute.toString().padLeft(2, '0')}'
          '-${c.hour.toString().padLeft(2, '0')}:${c.minute.toString().padLeft(2, '0')}',
        );
      } else {
        parts.add('$day Kapalı');
      }
    }
    return parts.join(', ');
  }

  Future<void> _pickTime(String day, bool isOpen) async {
    final initial = isOpen ? (_open[day] ?? const TimeOfDay(hour: 9, minute: 0))
        : (_close[day] ?? const TimeOfDay(hour: 18, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    setState(() {
      if (isOpen) {
        _open[day] = picked;
      } else {
        _close[day] = picked;
      }
      widget.ctrl.text = _buildText();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoChip('Çalışma saatleriniz mağaza profilinizde gösterilir.'),
          const SizedBox(height: 16),
          ...List.generate(_days.length, (i) {
            final day = _days[i];
            final isEnabled = _enabled[day] ?? false;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isEnabled
                      ? AppPalette.storePrimary.withOpacity(0.3)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      day,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isEnabled ? AppPalette.storePrimary : Colors.grey,
                      ),
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: (v) => setState(() {
                      _enabled[day] = v;
                      widget.ctrl.text = _buildText();
                    }),
                    activeColor: AppPalette.storePrimary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (isEnabled) ...[
                    const Spacer(),
                    _TimeButton(
                      time: _open[day],
                      label: 'Açılış',
                      onTap: () => _pickTime(day, true),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('–', style: TextStyle(color: Colors.grey)),
                    ),
                    _TimeButton(
                      time: _close[day],
                      label: 'Kapanış',
                      onTap: () => _pickTime(day, false),
                    ),
                  ] else ...[
                    const Spacer(),
                    Text('Kapalı', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.time, required this.label, required this.onTap});

  final TimeOfDay? time;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = time != null
        ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
        : label;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppPalette.storePrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppPalette.storePrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.storePrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.storePrimary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppPalette.storePrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppPalette.storePrimary.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDeco(String hint, BuildContext context, {IconData? prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    filled: true,
    fillColor: (context as Element).widget is BuildContext
        ? Colors.white
        : Theme.of(context).colorScheme.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    counterText: '',
  );
}
