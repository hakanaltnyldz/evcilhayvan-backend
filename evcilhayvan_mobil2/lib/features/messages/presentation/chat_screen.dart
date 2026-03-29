import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:evcilhayvan_mobil2/core/socket_service.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/core/providers/socket_provider.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/messages/data/repositories/message_repository.dart';
import 'package:evcilhayvan_mobil2/features/messages/domain/models/message_model.dart';
import 'package:evcilhayvan_mobil2/features/messages/domain/models/conservation_model.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/constants.dart';
import 'package:evcilhayvan_mobil2/features/social/data/repositories/post_repository.dart';
import 'package:evcilhayvan_mobil2/core/widgets/block_report_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String receiverName;
  final String? receiverAvatarUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.receiverName,
    this.receiverAvatarUrl,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

enum _ChatEntryType { date, message }

class _ChatEntry {
  final _ChatEntryType type;
  final DateTime? date;
  final Message? message;

  _ChatEntry._(this.type, {this.date, this.message});

  factory _ChatEntry.date(DateTime date) => _ChatEntry._(
        _ChatEntryType.date,
        date: date,
      );

  factory _ChatEntry.message(Message message) => _ChatEntry._(
        _ChatEntryType.message,
        message: message,
      );
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  // Socket service provider'dan alınacak (singleton)
  SocketService get _socketService => ref.read(socketServiceProvider);
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  final List<Message> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSending = false;
  bool _showScrollToBottom = false;
  bool _isInitialized = false; // CRITICAL: Prevent double initialization

  // Ses kaydı
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;

  // Conversation detayları
  Conversation? _conversation;
  String? _actualReceiverName;
  String? _actualReceiverAvatar;

  // Mesaj arama
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Typing indicator
  bool _isOtherTyping = false;

  List<_ChatEntry> _buildEntries() {
    final entries = <_ChatEntry>[];
    DateTime? lastDate;

    for (final message in _messages) {
      final createdAt = message.createdAt.toLocal();
      final messageDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

      if (lastDate == null || !_isSameDay(lastDate, messageDate)) {
        entries.add(_ChatEntry.date(messageDate));
        lastDate = messageDate;
      }

      entries.add(_ChatEntry.message(message));
    }

    return entries;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateLabel(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (_isSameDay(today, target)) {
      return l10n.today;
    }
    if (_isSameDay(today.subtract(const Duration(days: 1)), target)) {
      return l10n.tomorrow;
    }

    // Format as day month year using locale-aware intl or simple format
    return '${target.day}.${target.month.toString().padLeft(2, '0')}.${target.year}';
  }

  bool _isFirstMessage(List<_ChatEntry> entries, int index) {
    final current = entries[index];
    if (current.type != _ChatEntryType.message) return false;
    for (var i = index - 1; i >= 0; i--) {
      final previous = entries[i];
      if (previous.type == _ChatEntryType.date) {
        return true;
      }
      if (previous.type == _ChatEntryType.message) {
        return previous.message!.sender.id != current.message!.sender.id;
      }
    }
    return true;
  }

  void _showInfoSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _deleteConversation() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dl10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(dl10n.chatDeleteTitle),
          content: Text(dl10n.chatDeleteContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dl10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(dl10n.delete),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await ref.read(messageRepositoryProvider).deleteConversation(
            widget.conversationId,
          );
      ref.invalidate(conversationsProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showInfoSnack(l10n.chatDeleteError(e.toString()));
    }
  }

  void _showConversationActions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final sl10n = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: Text(sl10n.chatRefresh),
                  onTap: () {
                    Navigator.pop(ctx);
                    _fetchMessages();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(sl10n.chatNotifPrefs),
                  subtitle: Text(sl10n.chatNotifPrefsSub),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showInfoSnack(sl10n.chatNotifPrefsInfo);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(sl10n.chatDeleteFromList),
                  subtitle: Text(sl10n.chatDeleteFromListSub),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteConversation();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: Colors.red),
                  title: Text(sl10n.chatBlockReport,
                      style: const TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    final otherId = _conversation?.otherParticipant.id;
                    final otherName = _actualReceiverName ?? widget.receiverName;
                    if (otherId != null && otherId.isNotEmpty) {
                      showBlockReportSheet(context,
                          userId: otherId, userName: otherName);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onAttachmentTap() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFF2D6A4F)),
                ),
                title: Text(AppLocalizations.of(ctx)!.chatSelectFromGallery),
                subtitle: Text(AppLocalizations.of(ctx)!.chatSelectFromGallerySub),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.green),
                ),
                title: Text(AppLocalizations.of(ctx)!.chatCamera),
                subtitle: Text(AppLocalizations.of(ctx)!.chatCameraSub),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: kImageQualityHigh,
      );

      if (image == null) return;

      final File imageFile = File(image.path);
      await _sendImageMessage(imageFile);
    } catch (e) {
      _showInfoSnack(AppLocalizations.of(context)!.chatErrImagePick(e.toString()));
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _showInfoSnack(AppLocalizations.of(context)!.chatErrMicPermission);
        return;
      }
      final dir = await getTemporaryDirectory();
      _recordingPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: _recordingPath!,
      );
      setState(() => _isRecording = true);
    } catch (e) {
      _showInfoSnack(AppLocalizations.of(context)!.chatErrRecordStart(e.toString()));
    }
  }

  Future<void> _stopAndSendRecording() async {
    if (!_isRecording) return;
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path == null) return;
      final audioFile = File(path);
      if (!await audioFile.exists()) return;
      await _sendAudioMessage(audioFile);
    } catch (e) {
      setState(() => _isRecording = false);
      _showInfoSnack(AppLocalizations.of(context)!.chatErrAudioSend(e.toString()));
    }
  }

  Future<void> _sendAudioMessage(File audioFile) async {
    if (_isSending) return;
    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;

    setState(() => _isSending = true);
    final pendingMessage = Message(
      id: 'local-audio-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversationId,
      sender: currentUser,
      text: AppLocalizations.of(context)!.chatAudioMsg,
      type: 'AUDIO',
      createdAt: DateTime.now(),
      audioUrl: audioFile.path,
    );
    setState(() => _messages.add(pendingMessage));
    _scrollToBottom();

    try {
      final repo = ref.read(messageRepositoryProvider);
      final saved = await repo.sendAudioMessage(
        conversationId: widget.conversationId,
        audioFile: audioFile,
      );
      setState(() {
        final index = _messages.indexWhere((m) => m.id == pendingMessage.id);
        if (index != -1) {
          _messages[index] = saved;
        }
      });
      _socketService.sendMessage(
        conversationId: saved.conversationId,
        message: {
          '_id': saved.id,
          'conversationId': saved.conversationId,
          'text': saved.text,
          'type': saved.type,
          'audioUrl': saved.audioUrl,
          'createdAt': saved.createdAt.toIso8601String(),
          'sender': {
            '_id': saved.sender.id,
            'name': saved.sender.name,
            'email': saved.sender.email,
          },
        },
      );
    } catch (e) {
      setState(() => _messages.removeWhere((m) => m.id == pendingMessage.id));
      _showInfoSnack(AppLocalizations.of(context)!.chatErrAudioSend(e.toString()));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendImageMessage(File imageFile) async {
    if (_isSending) return;

    final currentUser = ref.read(authProvider);
    if (currentUser == null) {
      _showInfoSnack(AppLocalizations.of(context)!.chatErrLoginRequiredImage);
      return;
    }

    setState(() => _isSending = true);

    // Optimistic UI: Geçici mesaj ekle
    final pendingMessage = Message(
      id: 'local-img-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversationId,
      sender: currentUser,
      text: '',
      type: 'IMAGE',
      createdAt: DateTime.now(),
      imageUrl: imageFile.path, // Geçici olarak local path
    );

    setState(() => _messages.add(pendingMessage));
    _scrollToBottom();

    try {
      final repo = ref.read(messageRepositoryProvider);
      final saved = await repo.sendImageMessage(
        conversationId: widget.conversationId,
        imageFile: imageFile,
      );

      setState(() {
        final index = _messages.indexWhere((m) => m.id == pendingMessage.id);
        if (index != -1) {
          _messages[index] = saved;
        } else {
          _messages.add(saved);
        }
      });

      // Socket üzerinden yayınla
      _socketService.sendMessage(
        conversationId: saved.conversationId,
        message: {
          '_id': saved.id,
          'conversationId': saved.conversationId,
          'text': saved.text,
          'type': saved.type,
          'imageUrl': saved.imageUrl,
          'createdAt': saved.createdAt.toIso8601String(),
          'sender': {
            '_id': saved.sender.id,
            'name': saved.sender.name,
            'email': saved.sender.email,
          },
        },
      );
    } catch (e) {
      setState(() {
        _messages.removeWhere((m) => m.id == pendingMessage.id);
      });
      _showInfoSnack(AppLocalizations.of(context)!.chatErrImageSend(e.toString()));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _onEmojiTap() {
    // Emoji keyboard not yet implemented
  }

  Widget _buildComposer(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: theme.colorScheme.surface.withOpacity(0.92),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _onAttachmentTap,
              icon: const Icon(Icons.add_photo_alternate_outlined),
            ),
            IconButton(
              onPressed: _onEmojiTap,
              icon: const Icon(Icons.emoji_emotions_outlined),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _inputFocusNode,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.chatMsgHint,
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: _isRecording
                  ? GestureDetector(
                      onLongPressEnd: (_) => _stopAndSendRecording(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.stop_rounded, color: Colors.white),
                      ),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [const Color(0xFF2D6A4F), const Color(0xFF52B788)]),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: _controller.text.isEmpty
                          ? GestureDetector(
                              onLongPress: _startRecording,
                              onLongPressEnd: (_) => _stopAndSendRecording(),
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(Icons.mic_rounded, color: Colors.white),
                              ),
                            )
                          : IconButton(
                              onPressed: _isSending ? null : _sendMessage,
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded, color: Colors.white),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessageForMe(Message message) async {
    try {
      await ref.read(messageRepositoryProvider).deleteMessageForMe(message.id);
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == message.id);
        if (idx != -1) {
          _messages[idx] = Message(
            id: message.id,
            conversationId: message.conversationId,
            sender: message.sender,
            text: message.text,
            createdAt: message.createdAt,
            isDeletedForMe: true,
          );
        }
      });
    } catch (e) {
      _showInfoSnack(AppLocalizations.of(context)!.chatErrMsgDelete(e.toString()));
    }
  }

  Future<void> _reactToMessage(Message message, String emoji) async {
    try {
      final reactions = await ref.read(postRepositoryProvider).reactToMessage(
        message.conversationId,
        message.id,
        emoji,
      );
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == message.id);
        if (idx != -1) {
          final parsed = Map<String, List<String>>.fromEntries(
            reactions.entries.map((e) {
              final val = e.value;
              return MapEntry(e.key, val is List ? val.map((v) => v.toString()).toList() : <String>[]);
            }),
          );
          _messages[idx] = _messages[idx].copyWith(reactions: parsed);
        }
      });
    } catch (e) {
      _showInfoSnack(AppLocalizations.of(context)!.chatErrReaction(e.toString()));
    }
  }

  @override
  void initState() {
    super.initState();
    print('🔵 ChatScreen initState - conversationId: ${widget.conversationId}');
    _scrollController.addListener(_handleScrollPosition);
    // Mikrofon/send butonunu yeniden render için controller değişimini dinle
    _controller.addListener(() => setState(() {}));

    // CRITICAL FIX: Run initialization AFTER first frame to avoid ANR/crash
    // This allows the UI to render first, then load data asynchronously
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔵 Post-frame callback - starting _initialiseChat');
      if (mounted && !_isInitialized) {
        _isInitialized = true;
        _initialiseChat().catchError((e) {
          print('❌ CRITICAL ERROR in _initialiseChat: $e');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = e.toString();
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    print('🔵 ChatScreen dispose - cleaning up resources');

    // Clear current chat conversation
    try {
      ref.read(currentChatConversationProvider.notifier).state = null;
    } catch (e) {
      print('⚠️ Error clearing current chat conversation: $e');
    }

    // Leave socket room
    try {
      _socketService.leaveRoom(widget.conversationId);
      print('✅ Left socket room: ${widget.conversationId}');
    } catch (e) {
      print('⚠️ Error leaving socket room: $e');
    }

    // Dispose controllers
    _controller.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _audioRecorder.dispose();

    super.dispose();
    print('✅ ChatScreen disposed successfully');
  }

  void _handleScrollPosition() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    final shouldShow = _scrollController.offset < threshold;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  Future<void> _initialiseChat() async {
    if (!mounted) {
      print('⚠️ Widget not mounted, aborting _initialiseChat');
      return;
    }

    print('🔵 _initialiseChat started');

    // Bu sohbette olduğumuzu işaretle (bildirim göstermemek için)
    try {
      ref.read(currentChatConversationProvider.notifier).state = widget.conversationId;
      print('✅ Set current chat conversation');
    } catch (e) {
      print('❌ Failed to set current chat conversation: $e');
    }

    // Önce mesajları çek - ama await YAPMA UI bloke olmasın
    if (!mounted) return;
    print('🔵 Starting to fetch messages');
    _fetchMessages().then((_) {
      if (mounted) {
        print('✅ Messages fetched successfully');
      }
    }).catchError((e) {
      print('❌ Failed to fetch messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    });

    // Socket'i bağla - ama bu da bloke etmesin
    if (!mounted) return;
    Future.delayed(Duration(milliseconds: 100), () async {
      if (!mounted) {
        print('⚠️ Widget disposed before socket connection');
        return;
      }

      try {
        print('🔵 Connecting to socket...');
        await _socketService.connect();
        print('✅ Socket connected');

        if (!mounted) return;
        _socketService.joinRoom(widget.conversationId);
        print('✅ Joined room: ${widget.conversationId}');

        _socketService.onMessage((data) {
          if (!mounted) return;
          try {
            final map = Map<String, dynamic>.from(data as Map);
            final raw = map['message'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(map['message'] as Map)
                : map;
            final incoming = Message.fromJson(raw);
            if (incoming.conversationId != widget.conversationId) return;
            final exists = _messages.any((m) => m.id == incoming.id);
            if (!exists && mounted) {
              setState(() {
                _messages.add(incoming);
                _isOtherTyping = false; // hide typing indicator when message arrives
              });
              _scrollToBottom();
            }
          } catch (e) {
            debugPrint('⚠️ Gelen mesaj parse edilemedi: $e');
          }
        });

        // Typing indicator events
        _socketService.onEvent('user:typing', (data) {
          if (!mounted) return;
          try {
            final d = data is Map ? Map<String, dynamic>.from(data as Map) : <String, dynamic>{};
            if (d['conversationId'] == widget.conversationId) {
              setState(() => _isOtherTyping = true);
            }
          } catch (_) {}
        });
        _socketService.onEvent('user:stopped_typing', (data) {
          if (!mounted) return;
          try {
            final d = data is Map ? Map<String, dynamic>.from(data as Map) : <String, dynamic>{};
            if (d['conversationId'] == widget.conversationId) {
              setState(() => _isOtherTyping = false);
            }
          } catch (_) {}
        });
      } catch (e) {
        print('❌ Socket bağlantısı kurulamadı: $e');
      }
    });

    // Conversation detayını asenkron çek - bloke etme
    if (!mounted) return;
    Future.delayed(Duration(milliseconds: 200), () {
      if (!mounted) {
        print('⚠️ Widget disposed before fetching conversation details');
        return;
      }
      print('🔵 Fetching conversation details');
      _fetchConversationDetails();
    });

    print('✅ _initialiseChat completed (async operations still running)');
  }

  Future<void> _fetchConversationDetails() async {
    try {
      final currentUser = ref.read(authProvider);
      if (currentUser == null) return;

      final repo = ref.read(messageRepositoryProvider);
      final conv = await repo.getConversationById(widget.conversationId, currentUser.id);

      if (!mounted) return;
      setState(() {
        _conversation = conv;
        _actualReceiverName = conv.otherParticipant.name;
        _actualReceiverAvatar = conv.otherParticipant.avatarUrl;
      });
    } catch (e) {
      debugPrint('⚠️ Conversation detayı alınamadı: $e');
      // Widget'tan gelen değerleri kullan
    }
  }

  Future<void> _fetchMessages() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } catch (e) {
      print('⚠️ setState failed in _fetchMessages init: $e');
      return;
    }

    try {
      final repo = ref.read(messageRepositoryProvider);

      print('🔵 Fetching messages for conversation: ${widget.conversationId}');
      final fetched = await repo.getMessages(widget.conversationId);
      print('✅ Fetched ${fetched.length} messages');

      // Sort in background to avoid UI freeze
      final sorted = List<Message>.from(fetched)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (!mounted) return;
      try {
        setState(() {
          _messages
            ..clear()
            ..addAll(sorted);
        });
        print('✅ Messages added to state');
      } catch (e) {
        print('⚠️ setState failed when adding messages: $e');
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print('🔵 Scrolling to bottom');
          _scrollToBottom();
        }
      });
      ref.read(messageRepositoryProvider).markAsRead(widget.conversationId).ignore();
    } catch (e, stackTrace) {
      print('❌ Error fetching messages: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;
      try {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      } catch (e) {
        print('⚠️ setState failed when setting error: $e');
      }
    } finally {
      if (!mounted) return;
      try {
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        print('⚠️ setState failed in finally block: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUser = ref.read(authProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatErrLoginRequired)),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    final pendingMessage = Message(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversationId,
      sender: currentUser,
      text: text,
      type: 'TEXT',
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(pendingMessage);
      _controller.clear();
    });
    _scrollToBottom();
    _inputFocusNode.requestFocus();

    try {
      final repo = ref.read(messageRepositoryProvider);
      final saved = await repo.sendMessage(
        conversationId: widget.conversationId,
        text: text,
      );

      setState(() {
        final index =
            _messages.indexWhere((element) => element.id == pendingMessage.id);
        if (index != -1) {
          _messages[index] = saved;
        } else {
          _messages.add(saved);
        }
      });

      // ChatScreen içinde, kaydedilmiş mesaja göre yay:
      _socketService.sendMessage(
        conversationId: saved.conversationId,
        message: {
          '_id': saved.id,
          'conversationId': saved.conversationId,
          'text': saved.text,
          'type': saved.type,
          'createdAt': saved.createdAt.toIso8601String(),
          'sender': {
            '_id': saved.sender.id,
            'name': saved.sender.name,
            'email': saved.sender.email,
            // avatarUrl gerekiyorsa ekle
          },
        },
      );

    } catch (e) {
      setState(() {
        _messages.removeWhere((element) => element.id == pendingMessage.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatErrMsgSend(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // İlan kartı widget'ı
  Widget _buildPetContextCard(ThemeData theme) {
    final pet = _conversation?.relatedPet;
    if (pet == null && _conversation?.relatedPetId == null) {
      return const SizedBox.shrink();
    }

    final petName = pet?.name ?? AppLocalizations.of(context)!.petDetailTitle;
    final petImage = pet?.images.isNotEmpty == true ? pet!.images.first : null;
    final advertType = _conversation?.advertType ?? pet?.advertType;
    final isAdoption = advertType == 'adoption';

    return GestureDetector(
      onTap: () {
        final petId = pet?.id ?? _conversation?.relatedPetId ?? _conversation?.contextId;
        if (petId != null) {
          context.pushNamed('pet-detail', pathParameters: {'id': petId});
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isAdoption
                ? [Colors.green.shade50, Colors.green.shade100]
                : [const Color(0xFFD8F3DC), const Color(0xFFD8F3DC)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAdoption ? Colors.green.shade200 : const Color(0xFF52B788),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: context.cardColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: petImage != null
                  ? Image.network(
                      petImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.pets,
                        color: isAdoption ? Colors.green : const Color(0xFF52B788),
                      ),
                    )
                  : Icon(
                      Icons.pets,
                      color: isAdoption ? Colors.green : const Color(0xFF52B788),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    petName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAdoption ? Colors.green : const Color(0xFF52B788),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAdoption ? AppLocalizations.of(context)!.advertTypeAdoption : AppLocalizations.of(context)!.advertTypeMating,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (pet?.species != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          _getSpeciesLabel(pet!.species),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isAdoption ? Colors.green : const Color(0xFF52B788),
            ),
          ],
        ),
      ),
    );
  }

  String _getSpeciesLabel(String species) {
    final l10n = AppLocalizations.of(context)!;
    switch (species.toLowerCase()) {
      case 'dog':
        return l10n.speciesDog;
      case 'cat':
        return l10n.speciesCat;
      case 'bird':
        return l10n.speciesBird;
      default:
        return l10n.speciesOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(authProvider);
    final allEntries = _buildEntries();
    final entries = _isSearching && _searchQuery.isNotEmpty
        ? allEntries
            .where((e) =>
                e.type == _ChatEntryType.message &&
                (e.message?.text ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList()
        : allEntries;

    // Gerçek alıcı bilgilerini kullan (conversation'dan veya widget'tan)
    final displayName = _actualReceiverName ?? widget.receiverName;
    final displayAvatar = _actualReceiverAvatar ?? widget.receiverAvatarUrl;

    // Sohbet tipi etiketi
    final contextLabel = _conversation?.contextType == 'MATCHING'
        ? l10n.chatTypeMatching
        : _conversation?.contextType == 'ADOPTION'
            ? l10n.chatTypeAdoption
            : l10n.chatTypeGeneral;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          print('🔵 Screen popped - cleaning up');
          // Cleanup already handled in dispose()
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        floatingActionButton: _showScrollToBottom
            ? FloatingActionButton.small(
                onPressed: _scrollToBottom,
                child: const Icon(Icons.arrow_downward_rounded),
              )
            : null,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              print('🔵 Back button pressed - navigating back');
              Navigator.of(context).pop();
            },
            tooltip: l10n.chatTooltipBack,
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.18),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: displayAvatar != null
                    ? NetworkImage(displayAvatar)
                    : null,
                child: displayAvatar == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: theme.colorScheme.onPrimary),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            contextLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.search_off_rounded : Icons.search_rounded),
              tooltip: _isSearching ? l10n.chatTooltipCloseSearch : l10n.chatTooltipSearch,
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchQuery = '';
                    _searchController.clear();
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: _showConversationActions,
            ),
          ],
        ),
        body: ModernBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Arama çubuğu
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _isSearching
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: l10n.chatSearchHint,
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _searchController.clear();
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                // İlan kartı
                _buildPetContextCard(theme),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? _ErrorView(
                                message: _errorMessage!,
                                onRetry: _fetchMessages,
                              )
                            : entries.isEmpty
                                ? _isSearching && _searchQuery.isNotEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                                            const SizedBox(height: 8),
                                            Text(l10n.chatSearchNoResults(_searchQuery), style: theme.textTheme.bodyMedium),
                                          ],
                                        ),
                                      )
                                    : const _EmptyChatState()
                                : RefreshIndicator(
                                    onRefresh: _fetchMessages,
                                    child: ListView.builder(
                                    controller: _scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    padding:
                                        const EdgeInsets.fromLTRB(12, 12, 12, 24),
                                    itemCount: entries.length,
                                    itemBuilder: (context, index) {
                                      final entry = entries[index];
                                      if (entry.type == _ChatEntryType.date) {
                                        return _DateSeparator(
                                          label: _formatDateLabel(entry.date!, l10n),
                                        );
                                      }
                                      final message = entry.message!;
                                      if (message.type == 'SYSTEM') {
                                        return _SystemMessage(text: message.text);
                                      }
                                      final isMine =
                                          message.sender.id == currentUser?.id;
                                      final isFirstInGroup =
                                          _isFirstMessage(entries, index);
                                      return _MessageBubble(
                                        message: message,
                                        isMine: isMine,
                                        isFirstInGroup: isFirstInGroup,
                                        onDeleteForMe: isMine
                                            ? () => _deleteMessageForMe(message)
                                            : null,
                                        otherParticipantId: _conversation?.otherParticipant.id,
                                        onReact: (emoji) => _reactToMessage(message, emoji),
                                        currentUserId: currentUser?.id,
                                      )
                                          .animate(key: ValueKey(message.id))
                                          .fadeIn(duration: 180.ms, curve: Curves.easeOut)
                                          .slideX(
                                            begin: isMine ? 0.08 : -0.08,
                                            duration: 180.ms,
                                            curve: Curves.easeOut,
                                          );
                                    },
                                  ),
                                  ),
                  ),
                ),
                // Typing indicator
                if (_isOtherTyping)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: const _TypingDotsWidget(),
                  ),
                _buildComposer(theme),
              ],
            ),
          ),
        ),
      ), // End of Scaffold
    ); // End of PopScope
  }

}

class _DateSeparator extends StatelessWidget {
  final String label;

  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.colorScheme.outline.withOpacity(0.2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: dividerColor, thickness: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Divider(color: dividerColor, thickness: 1)),
        ],
      ),
    );
  }
}

class _SystemMessage extends StatelessWidget {
  final String text;

  const _SystemMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final bool isFirstInGroup;
  final VoidCallback? onDeleteForMe;
  final String? otherParticipantId;
  final void Function(String emoji)? onReact;
  final String? currentUserId;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isFirstInGroup,
    this.onDeleteForMe,
    this.otherParticipantId,
    this.onReact,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isMine
        ? LinearGradient(colors: [const Color(0xFF2D6A4F), const Color(0xFF52B788)])
        : LinearGradient(colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceVariant.withOpacity(0.6),
          ]);

    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final textColor =
        isMine ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final topMargin = isFirstInGroup ? 12.0 : 4.0;

    final isDeleted = message.isDeletedForMe;

    final bubble = Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: isDeleted
            ? null
            : () {
                showModalBottomSheet<void>(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Emoji reaction bar
                        if (onReact != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: ['❤️', '👍', '😂', '😮', '😢', '🎉']
                                  .map((e) => GestureDetector(
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          onReact?.call(e);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surfaceVariant,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(e, style: const TextStyle(fontSize: 24)),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        const Divider(height: 1),
                        if (onDeleteForMe != null)
                          ListTile(
                            leading: const Icon(Icons.delete_outline),
                            title: Text(AppLocalizations.of(ctx)!.chatDeleteMsgForMe),
                            onTap: () {
                              Navigator.pop(ctx);
                              onDeleteForMe?.call();
                            },
                          ),
                        ListTile(
                          leading: const Icon(Icons.copy_outlined),
                          title: Text(AppLocalizations.of(ctx)!.chatCopyMsg),
                          onTap: () {
                            Navigator.pop(ctx);
                            _copyToClipboard(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          margin: EdgeInsets.fromLTRB(8, topMargin, 8, 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMine ? 18 : (isFirstInGroup ? 20 : 10)),
              topRight: Radius.circular(isMine ? (isFirstInGroup ? 20 : 10) : 18),
              bottomLeft: const Radius.circular(20),
              bottomRight: const Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDeleted)
                Text(
                  AppLocalizations.of(context)!.chatMsgDeletedSelf,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                )
              else if (message.type == 'IMAGE' && message.imageUrl != null)
                _buildImageContent(context, theme, textColor)
              else if (message.type == 'AUDIO' && message.audioUrl != null)
                _AudioBubble(audioUrl: message.audioUrl!, apiBaseUrl: apiBaseUrl)
              else
                Text(
                  message.text,
                  style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    _buildReadStatus(textColor),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap with reactions if needed
    final reactionsWidget = _buildReactions(context);
    if (reactionsWidget == null) return bubble;

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(alignment: alignment, child: _unwrapAlign(bubble)),
          reactionsWidget,
        ],
      ),
    );
  }

  // Extract child from Align widget (bubble already has Align at root)
  Widget _unwrapAlign(Widget w) {
    if (w is Align) return w.child ?? w;
    return w;
  }

  Widget? _buildReactions(BuildContext context) {
    if (message.reactions.isEmpty) return null;
    final nonEmpty = message.reactions.entries.where((e) => e.value.isNotEmpty).toList();
    if (nonEmpty.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Wrap(
        spacing: 4,
        children: nonEmpty.map((entry) {
          final emoji = entry.key;
          final count = entry.value.length;
          final iReacted = currentUserId != null && entry.value.contains(currentUserId);
          return GestureDetector(
            onTap: () => onReact?.call(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: iReacted ? const Color(0xFF2D6A4F).withOpacity(0.15) : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: iReacted ? const Color(0xFF2D6A4F) : Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: Text(
                count > 1 ? '$emoji $count' : emoji,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, ThemeData theme, Color textColor) {
    final imageUrl = message.imageUrl!;
    final isLocalImage = imageUrl.startsWith('/') || imageUrl.startsWith('file://');

    return GestureDetector(
      onTap: () {
        // Resmi tam ekranda göster
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _FullScreenImageView(
              imageUrl: isLocalImage ? imageUrl : '$apiBaseUrl$imageUrl',
              isLocal: isLocalImage,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 200,
            maxHeight: 250,
          ),
          child: isLocalImage
              ? Image.file(
                  File(imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImagePlaceholder(theme),
                )
              : CachedNetworkImage(
                  imageUrl: '$apiBaseUrl$imageUrl',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _buildImageLoading(theme),
                  errorWidget: (_, __, ___) => _buildImagePlaceholder(theme),
                ),
        ),
      ),
    );
  }

  Widget _buildImageLoading(ThemeData theme) {
    return Container(
      width: 200,
      height: 150,
      color: theme.colorScheme.surfaceVariant,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Container(
      width: 200,
      height: 150,
      color: theme.colorScheme.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            'Image unavailable',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadStatus(Color textColor) {
    // Eğer mesaj henüz sunucuya kaydedilmediyse (local ID ile başlıyorsa)
    final isPending = message.id.startsWith('local-');
    if (isPending) {
      return Icon(
        Icons.schedule,
        size: 14,
        color: textColor.withOpacity(0.5),
      );
    }

    // readBy listesinde karşı tarafın ID'si varsa mesaj okunmuş demektir
    final isRead = otherParticipantId != null &&
        message.readBy.contains(otherParticipantId);

    // Okundu: Çift mavi tik, Gönderildi: Çift gri tik
    if (isRead) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.done_all,
            size: 16,
            color: Colors.lightBlueAccent,
          ),
        ],
      );
    } else {
      // Gönderildi ama okunmadı
      return Icon(
        Icons.done_all,
        size: 16,
        color: textColor.withOpacity(0.5),
      );
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.copyTooltip)),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: theme.colorScheme.surface.withOpacity(0.92),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.12),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 52, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.messagesEmpty,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.messagesEmptyDesc,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.error,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime time) {
  final hours = time.hour.toString().padLeft(2, '0');
  final minutes = time.minute.toString().padLeft(2, '0');
  return '$hours:$minutes';
}

class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  final bool isLocal;

  const _FullScreenImageView({
    required this.imageUrl,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.success)),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: isLocal
              ? Image.file(
                  File(imageUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Ses Mesajı Bubble'ı ──────────────────────────────────────────────────────
class _AudioBubble extends StatefulWidget {
  final String audioUrl;
  final String apiBaseUrl;

  const _AudioBubble({required this.audioUrl, required this.apiBaseUrl});

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playing = state == PlayerState.playing);
    });
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _playing = false; _position = Duration.zero; });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
    } else {
      final url = widget.audioUrl.startsWith('http')
          ? widget.audioUrl
          : widget.audioUrl.startsWith('/')
              ? '${widget.apiBaseUrl}${widget.audioUrl}'
              : widget.audioUrl;
      if (widget.audioUrl.startsWith('/') || widget.audioUrl.startsWith('file://')) {
        await _player.play(DeviceFileSource(widget.audioUrl));
      } else {
        await _player.play(UrlSource(url));
      }
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _togglePlay,
          icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle, size: 32),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_fmt(_position)} / ${_fmt(_duration)}',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

/// Karşı tarafın yazdığını gösteren 3-nokta animasyonu.
class _TypingDotsWidget extends StatefulWidget {
  const _TypingDotsWidget();

  @override
  State<_TypingDotsWidget> createState() => _TypingDotsWidgetState();
}

class _TypingDotsWidgetState extends State<_TypingDotsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i * 0.2;
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = (_ctrl.value - delay).clamp(0.0, 1.0);
              final bounce = (t < 0.5 ? t * 2 : (1 - t) * 2);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6 + bounce * 0.4),
                ),
                transform: Matrix4.translationValues(0, -4 * bounce, 0),
              );
            },
          );
        }),
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.3, duration: 200.ms);
  }
}
