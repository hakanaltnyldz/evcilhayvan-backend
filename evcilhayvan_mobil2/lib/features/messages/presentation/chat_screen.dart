import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:evcilhayvan_mobil2/core/socket_service.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/core/providers/socket_provider.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/messages/data/repositories/message_repository.dart';
import 'package:evcilhayvan_mobil2/features/messages/domain/models/message_model.dart';
import 'package:evcilhayvan_mobil2/features/messages/domain/models/conservation_model.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
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

  // Conversation detayları
  Conversation? _conversation;
  String? _actualReceiverName;
  String? _actualReceiverAvatar;

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

  static const List<String> _monthNames = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (_isSameDay(today, target)) {
      return 'Bugün';
    }
    if (_isSameDay(today.subtract(const Duration(days: 1)), target)) {
      return 'Dün';
    }

    final month = _monthNames[target.month - 1];
    return '${target.day} $month ${target.year}';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sohbeti sil'),
        content: const Text(
          'Bu sohbeti kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
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
      _showInfoSnack('Sohbet silinemedi: $e');
    }
  }

  void _showConversationActions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
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
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: const Text('Sohbeti yenile'),
                  onTap: () {
                    Navigator.pop(context);
                    _fetchMessages();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Bildirim tercihleri'),
                  subtitle: const Text('Ayarlar > Bildirimler bölümünden yönetebilirsin'),
                  onTap: () {
                    Navigator.pop(context);
                    _showInfoSnack('Bildirim tercihlerini ayarlar ekranından düzenleyebilirsin.');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Sohbeti listeden sil'),
                  subtitle: const Text('Sohbetler ekranından da silebilirsin.'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteConversation();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: Colors.red),
                  title: const Text('Engelle / Şikayet Et',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('Galeriden Seç'),
                subtitle: const Text('Fotoğraf galerinizden seçin'),
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
                title: const Text('Kamera'),
                subtitle: const Text('Yeni fotoğraf çekin'),
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
        imageQuality: 85,
      );

      if (image == null) return;

      final File imageFile = File(image.path);
      await _sendImageMessage(imageFile);
    } catch (e) {
      _showInfoSnack('Resim seçilemedi: $e');
    }
  }

  Future<void> _sendImageMessage(File imageFile) async {
    if (_isSending) return;

    final currentUser = ref.read(authProvider);
    if (currentUser == null) {
      _showInfoSnack('Resim göndermek için giriş yapmalısınız.');
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
      _showInfoSnack('Resim gönderilemedi: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _onEmojiTap() {
    _showInfoSnack('Emoji klavyesi üzerinde çalışıyoruz.');
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
                decoration: const InputDecoration(
                  hintText: 'Mesajını yaz...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppPalette.accentGradient),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: IconButton(
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
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
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
      _showInfoSnack('Mesaj silinemedi: $e');
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
      _showInfoSnack('Reaksiyon gonderilemedi: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    print('🔵 ChatScreen initState - conversationId: ${widget.conversationId}');
    _scrollController.addListener(_handleScrollPosition);

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
              _errorMessage = 'Sohbet yüklenemedi: ${e.toString()}';
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
    _scrollController.dispose();
    _inputFocusNode.dispose();

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
          _errorMessage = 'Mesajlar yüklenemedi';
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
              setState(() => _messages.add(incoming));
              _scrollToBottom();
            }
          } catch (e) {
            debugPrint('⚠️ Gelen mesaj parse edilemedi: $e');
          }
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
        const SnackBar(content: Text('Mesaj göndermek için giriş yapmalısınız.')),
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
        SnackBar(content: Text('Mesaj gönderilemedi: $e')),
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

    final petName = pet?.name ?? 'İlan';
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
                : [Colors.purple.shade50, Colors.purple.shade100],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAdoption ? Colors.green.shade200 : Colors.purple.shade200,
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
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: petImage != null
                  ? Image.network(
                      petImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.pets,
                        color: isAdoption ? Colors.green : Colors.purple,
                      ),
                    )
                  : Icon(
                      Icons.pets,
                      color: isAdoption ? Colors.green : Colors.purple,
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
                          color: isAdoption ? Colors.green : Colors.purple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAdoption ? 'Sahiplendirme' : 'Eşleştirme',
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
              color: isAdoption ? Colors.green : Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  String _getSpeciesLabel(String species) {
    switch (species.toLowerCase()) {
      case 'dog':
        return 'Köpek';
      case 'cat':
        return 'Kedi';
      case 'bird':
        return 'Kuş';
      default:
        return 'Diğer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authProvider);
    final entries = _buildEntries();

    // Gerçek alıcı bilgilerini kullan (conversation'dan veya widget'tan)
    final displayName = _actualReceiverName ?? widget.receiverName;
    final displayAvatar = _actualReceiverAvatar ?? widget.receiverAvatarUrl;

    // Sohbet tipi etiketi
    final contextLabel = _conversation?.contextType == 'MATCHING'
        ? 'Eşleştirme sohbeti'
        : _conversation?.contextType == 'ADOPTION'
            ? 'Sahiplendirme sohbeti'
            : 'Sohbet';

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
            tooltip: 'Geri',
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
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: _showConversationActions,
            ),
          ],
        ),
        body: ModernBackground(
          child: SafeArea(
            child: Column(
              children: [
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
                                ? const _EmptyChatState()
                                : ListView.builder(
                                    controller: _scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    padding:
                                        const EdgeInsets.fromLTRB(12, 12, 12, 24),
                                    itemCount: entries.length,
                                    itemBuilder: (context, index) {
                                      final entry = entries[index];
                                      if (entry.type == _ChatEntryType.date) {
                                        return _DateSeparator(
                                          label: _formatDateLabel(entry.date!),
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
                                      );
                                    },
                                  ),
                  ),
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
        ? LinearGradient(colors: AppPalette.accentGradient)
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
                                            color: Colors.grey.shade100,
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
                            title: const Text('Bu mesajı kendimden sil'),
                            onTap: () {
                              Navigator.pop(ctx);
                              onDeleteForMe?.call();
                            },
                          ),
                        ListTile(
                          leading: const Icon(Icons.copy_outlined),
                          title: const Text('Kopyala'),
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
                  'Bu mesajı sildiniz',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                )
              else if (message.type == 'IMAGE' && message.imageUrl != null)
                _buildImageContent(context, theme, textColor)
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
                color: iReacted ? const Color(0xFF6C63FF).withOpacity(0.15) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: iReacted ? const Color(0xFF6C63FF) : Colors.grey.shade300,
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
            'Resim yüklenemedi',
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
      const SnackBar(content: Text('Mesaj panoya kopyalandı')),
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
              'Henüz mesaj yok',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Eşleşme sonrası ilk mesajını gönder ve sohbeti başlat.',
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
              'Sohbet yüklenemedi',
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
              child: const Text('Tekrar Dene'),
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
                const SnackBar(content: Text('Resim galeriye kaydedildi')),
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
