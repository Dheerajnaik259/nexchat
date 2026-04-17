import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/message_model.dart';
import '../../../services/supabase/auth_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';

/// Private 1:1 chat screen with real-time messaging
class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final List<MessageModel> _messages = [];
  final _supabase = Supabase.instance.client;
  late final RealtimeChannel _channel;
  String? _currentUserId;
  bool _isLoading = true;
  String _chatName = 'Chat';
  String? _chatAvatarUrl;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = AuthService.instance.currentUserId;
    _loadMessages();
    _loadChatInfo();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _supabase.removeChannel(_channel);
    super.dispose();
  }

  Future<void> _loadChatInfo() async {
    try {
      final chat = await _supabase
          .from('chats')
          .select()
          .eq('chat_id', widget.chatId)
          .maybeSingle();

      if (chat != null && mounted) {
        final participants = List<String>.from(chat['participants'] ?? []);
        final otherId = participants.firstWhere(
          (id) => id != _currentUserId,
          orElse: () => '',
        );

        if (otherId.isNotEmpty) {
          final user = await _supabase
              .from('users')
              .select()
              .eq('user_id', otherId)
              .maybeSingle();

          if (user != null && mounted) {
            setState(() {
              _chatName = user['display_name'] ?? 'User';
              _chatAvatarUrl = user['avatar_url'];
              _isOnline = user['is_online'] ?? false;
            });
          }
        } else if (chat['name'] != null) {
          setState(() => _chatName = chat['name']);
        }
      }
    } catch (e) {
      debugPrint('[ChatScreen] Error loading chat info: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', widget.chatId)
          .order('timestamp', ascending: true)
          .limit(50);

      if (mounted) {
        setState(() {
          _messages.clear();
          for (final json in response) {
            _messages.add(MessageModel.fromJson(json));
          }
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('[ChatScreen] Error loading messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToMessages() {
    _channel = _supabase
        .channel('chat:${widget.chatId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: widget.chatId,
          ),
          callback: (payload) {
            final newMessage = MessageModel.fromJson(payload.newRecord);
            if (mounted) {
              setState(() => _messages.add(newMessage));
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _currentUserId == null) return;

    final messageId =
        DateTime.now().millisecondsSinceEpoch.toString() +
        _currentUserId!.substring(0, 4);

    final message = MessageModel(
      messageId: messageId,
      chatId: widget.chatId,
      senderId: _currentUserId!,
      type: MessageType.text,
      encryptedText: text, // TODO: encrypt with EncryptionService
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    // Optimistic update
    setState(() => _messages.add(message));
    _scrollToBottom();

    try {
      await _supabase.from('messages').insert(message.toJson());

      // Update chat's last message
      await _supabase.from('chats').update({
        'last_message': {
          'text': text.length > 50 ? '${text.substring(0, 50)}...' : text,
          'sender_id': _currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'text',
        },
        'last_activity': DateTime.now().toIso8601String(),
      }).eq('chat_id', widget.chatId);
    } catch (e) {
      debugPrint('[ChatScreen] Error sending message: $e');
      // Mark as failed
      if (mounted) {
        final index = _messages.indexWhere((m) => m.messageId == messageId);
        if (index != -1) {
          setState(() {
            _messages[index] = _messages[index].copyWith(
              status: MessageStatus.failed,
            );
          });
        }
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.neonPurple,
                    ),
                  )
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),

          // Input bar
          MessageInputBar(
            onSendMessage: _sendMessage,
            onAttachmentTap: () {
              // TODO: show attachment picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attachments coming soon!'),
                  backgroundColor: AppColors.surfaceDark,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bgDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.neonPurple.withValues(alpha: 0.3),
            backgroundImage: _chatAvatarUrl != null
                ? NetworkImage(_chatAvatarUrl!)
                : null,
            child: _chatAvatarUrl == null
                ? Text(
                    _chatName.isNotEmpty ? _chatName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.neonPurple,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _chatName,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isOnline
                        ? AppColors.onlineDot
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_rounded, size: 22),
          onPressed: () {
            // TODO: video call
          },
        ),
        IconButton(
          icon: const Icon(Icons.call_rounded, size: 22),
          onPressed: () {
            // TODO: voice call
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          color: AppColors.surfaceDark,
          onSelected: (value) {
            // TODO: handle menu actions
          },
          itemBuilder: (context) => [
            _buildPopupItem('View contact', Icons.person_rounded),
            _buildPopupItem('Search', Icons.search_rounded),
            _buildPopupItem('Mute', Icons.notifications_off_rounded),
            _buildPopupItem('Wallpaper', Icons.wallpaper_rounded),
            _buildPopupItem('Clear chat', Icons.delete_sweep_rounded),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String text, IconData icon) {
    return PopupMenuItem(
      value: text.toLowerCase(),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(text, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.neonPurple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.neonPurple,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Say hello! 👋',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == _currentUserId;

        // Check if this is the last message from this sender
        final showTail = index == _messages.length - 1 ||
            _messages[index + 1].senderId != message.senderId;

        // Date separator
        Widget? dateSeparator;
        if (index == 0 ||
            !_isSameDay(
                _messages[index - 1].timestamp, message.timestamp)) {
          dateSeparator = _buildDateSeparator(message.timestamp);
        }

        return Column(
          children: [
            if (dateSeparator != null) dateSeparator,
            MessageBubble(
              message: message,
              isMe: isMe,
              showTail: showTail,
              onLongPress: () => _showMessageOptions(message),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) {
      label = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showMessageOptions(MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isMe = message.senderId == _currentUserId;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionTile(Icons.reply_rounded, 'Reply', () {
                Navigator.pop(context);
                // TODO: set reply
              }),
              _buildOptionTile(Icons.copy_rounded, 'Copy', () {
                Navigator.pop(context);
                // TODO: copy text
              }),
              _buildOptionTile(Icons.forward_rounded, 'Forward', () {
                Navigator.pop(context);
              }),
              if (isMe)
                _buildOptionTile(Icons.edit_rounded, 'Edit', () {
                  Navigator.pop(context);
                }),
              _buildOptionTile(
                Icons.delete_rounded,
                isMe ? 'Delete' : 'Delete for me',
                () {
                  Navigator.pop(context);
                },
                color: AppColors.error,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary, size: 22),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: color ?? AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}
