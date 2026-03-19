// lib/features/ai/presentation/screens/ai_assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:intl/intl.dart';

// ─── Sabit semptom listesi ──────────────────────────────────────────────────
// Backend'deki hastalık listesiyle paralel — token tasarrufu için Flutter'da da sabit
const _speciesSymptoms = {
  'Köpek': [
    'İştahsızlık', 'Ateş', 'İshal', 'Kusma', 'Öksürük',
    'Nefes darlığı', 'Uyuşukluk', 'Kanlı dışkı', 'Aşırı kaşınma',
    'Tüy dökülmesi', 'Topallama', 'Aşırı su içme', 'İdrar yapmama',
    'Şişmiş karın', 'Bilinç kaybı',
  ],
  'Kedi': [
    'İştahsızlık', 'Ateş', 'Kusma', 'İshal', 'Burun akıntısı',
    'Göz akıntısı', 'Nefes güçlüğü', 'İdrar yapamama', 'Aşırı su içme',
    'Kilo kaybı', 'Tüy yolma', 'Uyuşukluk', 'Kanlı idrar',
    'Sarılık', 'Nöbet/Titreme',
  ],
  'Kuş': [
    'Tüy döküyor', 'Yemiyor', 'Şişmiş/Kabarık', 'Burun akıntısı',
    'Nefes güçlüğü', 'İshal', 'Kusma', 'Ayakta duramıyor',
    'Nöbet geçiriyor', 'Kanıyor',
  ],
  'Diğer': [
    'İştahsızlık', 'Ateş', 'Uyuşukluk', 'Kaşınma',
    'İshal', 'Kusma', 'Nefes güçlüğü', 'Kilo kaybı',
  ],
};

// ─── Mod (Teşhis / Genel Sohbet) ──────────────────────────────────────────
enum _AiMode { diagnosis, general }

// ─── Mesaj modeli ──────────────────────────────────────────────────────────
class _ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  _ChatMessage({required this.role, required this.content, DateTime? t})
      : timestamp = t ?? DateTime.now();
}

// ─── Genel öneriler (mod=general için) ─────────────────────────────────────
const _generalSuggestions = [
  'Köpeğime ne kadar su vermeli?',
  'Kedi kumu ne sıklıkla değiştirilmeli?',
  'Yavru köpek eğitimi nasıl yapılır?',
  'Kedim neden gece bağırıyor?',
  'Köpek ısırması ne yapmalı?',
];

// ─── Screen ────────────────────────────────────────────────────────────────
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <_ChatMessage>[];
  bool _isLoading = false;
  final _dio = ApiClient().dio;
  final _timeFmt = DateFormat('HH:mm', 'tr');

  _AiMode _mode = _AiMode.diagnosis;
  String _selectedSpecies = 'Köpek';
  final Set<String> _selectedSymptoms = {};

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Semptomları metin olarak birleştir
  String _buildSymptomText() {
    final userText = _ctrl.text.trim();
    if (_selectedSymptoms.isEmpty) return userText;
    final symptoms = _selectedSymptoms.join(', ');
    if (userText.isNotEmpty) return '$_selectedSpecies, belirtiler: $symptoms. $userText';
    return '$_selectedSpecies, belirtiler: $symptoms.';
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = overrideText ?? _buildSymptomText();
    if (text.isEmpty || _isLoading) return;

    _ctrl.clear();
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _isLoading = true;
      _selectedSymptoms.clear(); // semptom seçimini sıfırla
    });
    _scrollToBottom();

    try {
      final payload = _messages
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final res = await _dio.post('/ai/chat', data: {
        'messages': payload,
        'mode': _mode == _AiMode.diagnosis ? 'diagnosis' : 'general',
      });
      final reply = res.data['reply'] as String? ?? 'Yanıt alınamadı.';
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', content: reply));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content: 'Üzgünüm, şu an yanıt veremiyorum. Lütfen tekrar deneyin.',
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppPalette.heroGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Pati Asistan',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // Mod geçişi
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<_AiMode>(
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                textStyle: const TextStyle(fontSize: 11),
              ),
              segments: const [
                ButtonSegment(
                  value: _AiMode.diagnosis,
                  icon: Icon(Icons.medical_services_outlined, size: 14),
                  label: Text('Teşhis'),
                ),
                ButtonSegment(
                  value: _AiMode.general,
                  icon: Icon(Icons.chat_outlined, size: 14),
                  label: Text('Genel'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() {
                _mode = s.first;
                _selectedSymptoms.clear();
              }),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sıfırla',
            onPressed: () => setState(() {
              _messages.clear();
              _selectedSymptoms.clear();
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // Teşhis modunda: tür + semptom seçici
          if (_mode == _AiMode.diagnosis) _buildDiagnosisPanel(theme),

          // Mesajlar
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome(theme)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) return _TypingIndicator();
                      final msg = _messages[index];
                      final isLatest = index == _messages.length - 1 && msg.role == 'assistant';
                      return _MessageBubble(
                        message: msg,
                        timeFmt: _timeFmt,
                        isDark: isDark,
                        isLatestAssistant: isLatest,
                      );
                    },
                  ),
          ),

          // Input
          _InputBar(
            ctrl: _ctrl,
            isLoading: _isLoading,
            selectedSymptoms: _selectedSymptoms,
            mode: _mode,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  // ─── Teşhis Paneli: Tür seçici + semptom chip'leri ─────────────────────
  Widget _buildDiagnosisPanel(ThemeData theme) {
    final symptoms = _speciesSymptoms[_selectedSpecies] ?? _speciesSymptoms['Diğer']!;
    return Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tür seçimi
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _speciesSymptoms.keys.map((species) {
                final selected = _selectedSpecies == species;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(species),
                    selected: selected,
                    selectedColor: AppPalette.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() {
                      _selectedSpecies = species;
                      _selectedSymptoms.clear();
                    }),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          // Semptom chip'leri
          Text(
            'Semptom seç (çoklu):',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: symptoms.map((s) {
              final selected = _selectedSymptoms.contains(s);
              return FilterChip(
                label: Text(s, style: const TextStyle(fontSize: 11)),
                selected: selected,
                selectedColor: AppPalette.secondary.withOpacity(0.85),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : null,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (_) => setState(() {
                  if (selected) {
                    _selectedSymptoms.remove(s);
                  } else {
                    _selectedSymptoms.add(s);
                  }
                }),
              );
            }).toList(),
          ),
          if (_selectedSymptoms.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Seçili: ${_selectedSymptoms.join(', ')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => _sendMessage(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Teşhis Et →'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcome(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppPalette.heroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _mode == _AiMode.diagnosis
              ? 'Semptom seç veya yaz → Teşhis al'
              : 'Evcil hayvanın hakkında ne sormak istiyorsun?',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          _mode == _AiMode.diagnosis
              ? 'Yukarıdan türü ve belirtileri seç,\nyoksa metin kutusuna yaz.'
              : 'Bakım, beslenme, eğitim hakkında\nkısa ve pratik yanıtlar alırsın.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant),
        ),
        if (_mode == _AiMode.general) ...[
          const SizedBox(height: 20),
          Text('Örnek sorular:',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: AppPalette.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _generalSuggestions.map((s) {
              return ActionChip(
                label: Text(s, style: const TextStyle(fontSize: 12)),
                onPressed: () => _sendMessage(s),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// ─── Karakter karakter ortaya çıkan metin ──────────────────────────────────
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool animate;

  const _TypewriterText({required this.text, this.style, this.animate = true});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _startTyping();
    } else {
      _charCount = widget.text.length;
    }
  }

  Future<void> _startTyping() async {
    // Metin kısaysa daha hızlı; uzunsa biraz daha yavaş
    final delay = widget.text.length < 80
        ? const Duration(milliseconds: 18)
        : const Duration(milliseconds: 12);
    for (int i = 0; i <= widget.text.length; i++) {
      if (!mounted) return;
      setState(() => _charCount = i);
      await Future.delayed(delay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text.substring(0, _charCount),
      style: widget.style,
    );
  }
}

// ─── Mesaj balonu ──────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final DateFormat timeFmt;
  final bool isDark;
  final bool isLatestAssistant;

  const _MessageBubble({
    required this.message,
    required this.timeFmt,
    required this.isDark,
    this.isLatestAssistant = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: AppPalette.heroGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppPalette.primary
                        : isDark
                            ? const Color(0xFF2A2843)
                            : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: isUser
                      ? Text(
                          message.content,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        )
                      : _TypewriterText(
                          text: message.content,
                          animate: isLatestAssistant,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                            height: 1.45,
                          ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeFmt.format(message.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.55),
                      fontSize: 10),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Typing indicator ──────────────────────────────────────────────────────
class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: AppPalette.heroGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: const PawDotLoading(color: AppPalette.primary),
          ),
        ],
      ),
    );
  }
}

// ─── Input bar ─────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isLoading;
  final Set<String> selectedSymptoms;
  final _AiMode mode;
  final void Function([String?]) onSend;

  const _InputBar({
    required this.ctrl,
    required this.isLoading,
    required this.selectedSymptoms,
    required this.mode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = mode == _AiMode.diagnosis
        ? 'Ek bilgi ekle veya direkt yaz...'
        : 'Sorunuzu yazın...';

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: isLoading ? null : () => onSend(),
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(13),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.send_rounded, size: 20),
          ),
        ],
      ),
    );

  }
}

