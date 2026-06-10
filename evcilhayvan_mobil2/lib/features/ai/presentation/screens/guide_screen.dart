// lib/features/ai/presentation/screens/guide_screen.dart
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

// ─── Model ──────────────────────────────────────────────────────────────────

class _NavAction {
  final String route;
  final Map<String, String> pathParams;
  final Map<String, String> queryParams;
  final Map<String, dynamic> extra;

  const _NavAction({
    required this.route,
    this.pathParams = const {},
    this.queryParams = const {},
    this.extra = const {},
  });

  factory _NavAction.fromJson(Map<String, dynamic> json) => _NavAction(
        route: json['route'] as String? ?? '',
        pathParams: Map<String, String>.from(json['pathParams'] as Map? ?? {}),
        queryParams: Map<String, String>.from(json['queryParams'] as Map? ?? {}),
        extra: Map<String, dynamic>.from(json['extra'] as Map? ?? {}),
      );
}

class _GuideMessage {
  final bool isUser;
  final String text;
  final _NavAction? action;
  final List<String> suggestions;

  const _GuideMessage({
    required this.isUser,
    required this.text,
    this.action,
    this.suggestions = const [],
  });
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class GuideScreen extends ConsumerStatefulWidget {
  const GuideScreen({super.key});

  @override
  ConsumerState<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends ConsumerState<GuideScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_GuideMessage>[];
  bool _loading = false;
  final _dio = ApiClient().dio;

  // Başlangıç önerileri — built at runtime from l10n
  List<String> _getInitSuggestions(AppLocalizations l10n) => [
    l10n.guideSug1,
    l10n.guideSug2,
    l10n.guideSug3,
    l10n.guideSug4,
    l10n.guideSug5,
    l10n.guideSug6,
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    _ctrl.clear();

    setState(() {
      _messages.add(_GuideMessage(isUser: true, text: text));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final res = await _dio.post('/api/ai/navigate', data: {'message': text});
      final body = res.data as Map<String, dynamic>;

      final reply = body['reply'] as String? ?? AppLocalizations.of(context)!.guideUnknown;
      final actionJson = body['action'] as Map<String, dynamic>?;
      final suggestions = List<String>.from(body['suggestions'] as List? ?? []);

      final action = actionJson != null ? _NavAction.fromJson(actionJson) : null;

      setState(() {
        _messages.add(_GuideMessage(
          isUser: false,
          text: reply,
          action: action,
          suggestions: suggestions,
        ));
        _loading = false;
      });
      _scrollToBottom();

      // Otomatik yönlendir (0.8sn gecikme — kullanıcı mesajı okusun)
      if (action != null && action.route.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) _navigate(action);
      }
    } catch (_) {
      setState(() {
        _messages.add(_GuideMessage(
          isUser: false,
          text: AppLocalizations.of(context)!.guideConnError,
        ));
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _navigate(_NavAction action) {
    final route = action.route;
    try {
      if (action.pathParams.isNotEmpty) {
        context.pushNamed(route,
            pathParameters: action.pathParams,
            queryParameters: action.queryParams,
            extra: action.extra.isEmpty ? null : action.extra);
      } else if (action.queryParams.isNotEmpty) {
        context.pushNamed(route,
            queryParameters: action.queryParams,
            extra: action.extra.isEmpty ? null : action.extra);
      } else if (action.extra.isNotEmpty) {
        context.pushNamed(route, extra: action.extra);
      } else {
        context.pushNamed(route);
      }
    } catch (_) {
      // Rota bulunamazsa sessizce geç
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF52B788)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assistant_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.guideTitle,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: AppLocalizations.of(context)!.guideNewChat,
              onPressed: () => setState(() => _messages.clear()),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildWelcome(theme) : _buildChat(theme),
          ),
          _buildInput(theme),
        ],
      ),
    );
  }

  Widget _buildWelcome(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4332), Color(0xFF52B788)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D6A4F).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.assistant_rounded, color: Colors.white, size: 38),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true, period: 2.5.seconds))
              .scale(begin: const Offset(1, 1), end: const Offset(1.07, 1.07), duration: 900.ms, curve: Curves.easeInOut),
        ),
        const SizedBox(height: 20),
        Text(
          AppLocalizations.of(context)!.guideWelcome,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.guideWelcomeSub,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.guideQuickOptions,
          style: theme.textTheme.labelLarge?.copyWith(
            color: const Color(0xFF2D6A4F),
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn(delay: 450.ms),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _getInitSuggestions(AppLocalizations.of(context)!).asMap().entries.map((e) {
            return ActionChip(
              label: Text(e.value, style: const TextStyle(fontSize: 13)),
              onPressed: () => _send(e.value),
              backgroundColor: const Color(0xFFD8F3DC),
              side: BorderSide(color: const Color(0xFF52B788)),
              labelStyle: TextStyle(color: const Color(0xFF2D6A4F), fontWeight: FontWeight.w600),
            ).animate(delay: (500 + e.key * 60).ms).fadeIn().scale(begin: const Offset(0.85, 0.85));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChat(ThemeData theme) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) {
          return _buildTyping();
        }
        final msg = _messages[i];
        return _buildMessage(msg, theme, i);
      },
    );
  }

  Widget _buildMessage(_GuideMessage msg, ThemeData theme, int index) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B4332), Color(0xFF52B788)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assistant_rounded, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF2D6A4F)
                        : const Color(0xFFD8F3DC),
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
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF1B4332),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
            ],
          ),

          // Navigasyon butonu
          if (!isUser && msg.action != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: FilledButton.icon(
                onPressed: () => _navigate(msg.action!),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(AppLocalizations.of(context)!.guideNavigateBtn),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 200.ms)
                  .scale(begin: const Offset(0.85, 0.85)),
            ),
          ],

          // Öneri chip'leri
          if (!isUser && msg.suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: msg.suggestions.asMap().entries.map((e) {
                  return ActionChip(
                    label: Text(e.value, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _send(e.value),
                    backgroundColor: const Color(0xFFD8F3DC),
                    side: BorderSide(color: const Color(0xFF52B788)),
                    labelStyle: TextStyle(color: const Color(0xFF2D6A4F), fontWeight: FontWeight.w600),
                  ).animate(delay: (e.key * 60).ms).fadeIn().slideX(begin: -0.1);
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    )
        .animate(key: ValueKey(index))
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.08, end: 0);
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4332), Color(0xFF52B788)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assistant_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          const PawDotLoading(),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.3);
  }

  Widget _buildInput(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              maxLines: 2,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.guideInputHint,
                hintStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _loading ? null : () => _send(_ctrl.text),
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(13),
              backgroundColor: const Color(0xFF2D6A4F),
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Icon(Icons.send_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
