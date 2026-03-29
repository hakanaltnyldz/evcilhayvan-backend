import 'dart:async';
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Timer? _debounce;

  final Map<String, bool> _prefs = {
    'messages': true,
    'matches': true,
    'adoptions': true,
    'vaccinations': true,
    'orderUpdates': true,
    'sitterBookings': true,
    'lostFoundNearby': true,
    'events': true,
    'birthdays': true,
  };

  static const _sections = [
    {
      'title': 'Mesajlaşma',
      'items': [
        {'key': 'messages', 'label': 'Mesajlar', 'subtitle': 'Yeni mesaj bildirimleri'},
      ],
    },
    {
      'title': 'Eşleştirme & Sahiplendirme',
      'items': [
        {'key': 'matches', 'label': 'Eşleşmeler', 'subtitle': 'Yeni eşleşme bildirimleri'},
        {'key': 'adoptions', 'label': 'Sahiplendirme', 'subtitle': 'Başvuru güncellemeleri'},
      ],
    },
    {
      'title': 'Sağlık & Hatırlatıcılar',
      'items': [
        {'key': 'vaccinations', 'label': 'Aşı Hatırlatıcıları', 'subtitle': 'Yaklaşan aşı tarihleri'},
        {'key': 'birthdays', 'label': 'Doğum Günleri', 'subtitle': 'Evcil hayvan doğum günleri'},
      ],
    },
    {
      'title': 'Mağaza',
      'items': [
        {'key': 'orderUpdates', 'label': 'Sipariş Güncellemeleri', 'subtitle': 'Sipariş durum değişiklikleri'},
      ],
    },
    {
      'title': 'Bakıcı',
      'items': [
        {'key': 'sitterBookings', 'label': 'Bakıcı Rezervasyonları', 'subtitle': 'Rezervasyon onay ve güncellemeleri'},
      ],
    },
    {
      'title': 'Etkinlik & Kayıp',
      'items': [
        {'key': 'lostFoundNearby', 'label': 'Yakınımdaki Kayıp İlanları', 'subtitle': 'Bölgenizdeki kayıp/bulunan ilanları'},
        {'key': 'events', 'label': 'Etkinlikler', 'subtitle': 'Yaklaşan etkinlik bildirimleri'},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      final res = await ApiClient().dio.get('/api/auth/me/notification-preferences');
      final data = res.data['preferences'] as Map<String, dynamic>? ?? {};
      setState(() {
        for (final key in _prefs.keys) {
          if (data[key] is bool) _prefs[key] = data[key] as bool;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Tercihler yüklenemedi';
        _loading = false;
      });
    }
  }

  void _onToggle(String key, bool value) {
    setState(() => _prefs[key] = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _savePreferences);
  }

  Future<void> _savePreferences() async {
    setState(() => _saving = true);
    try {
      await ApiClient().dio.patch('/api/auth/me/notification-preferences', data: Map<String, dynamic>.from(_prefs));
    } catch (_) {
      // silent fail — preferences are UI state, not critical
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: const Text('Bildirim Tercihleri'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() { _loading = true; _error = null; });
                          _loadPreferences();
                        },
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _sections.length,
                  itemBuilder: (context, sectionIndex) {
                    final section = _sections[sectionIndex];
                    final items = section['items'] as List<Map<String, String>>;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                          child: Text(
                            section['title'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D6A4F),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < items.length; i++) ...[
                                if (i > 0) Divider(height: 1, indent: 16, color: Colors.grey.shade100),
                                SwitchListTile(
                                  title: Text(
                                    items[i]['label']!,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(
                                    items[i]['subtitle']!,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                  value: _prefs[items[i]['key']!] ?? true,
                                  onChanged: (val) => _onToggle(items[i]['key']!, val),
                                  dense: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
