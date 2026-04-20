import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/media/media_picker_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/message_model.dart';
import '../controllers/chat_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/reply_preview_widget.dart';
import '../widgets/typing_indicator.dart';
import '../../../core/widgets/skeleton_loader.dart';

/// Private 1:1 chat screen with real-time messaging
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final _supabase = Supabase.instance.client;

  String? _currentUserId;
  String _chatName = 'Chat';
  String? _chatAvatarUrl;
  bool _isOnline = false;
  String? _lastSeen;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id;
    _loadChatInfo();

    _scrollController.addListener(() {
      final show = _scrollController.hasClients &&
          _scrollController.offset <
              _scrollController.position.maxScrollExtent - 200;
      if (show != _showScrollToBottom) {
        setState(() => _showScrollToBottom = show);
      }
    });

    // Mark messages as read when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider(widget.chatId).notifier).markAsRead();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatInfo() async {
    try {
      final chat = await _supabase
          .from('chats')
          .select()
          .eq('chat_id', widget.chatId)
          .maybeSingle();

      if (chat == null && mounted) {
        // Try with 'id' column
        final chat2 = await _supabase
            .from('chats')
            .select()
            .eq('id', widget.chatId)
            .maybeSingle();
        if (chat2 != null) {
          await _parseChat(chat2);
        }
        return;
      }

      if (chat != null && mounted) {
        await _parseChat(chat);
      }
    } catch (e) {
      debugPrint('[ChatScreen] Error loading chat info: $e');
    }
  }

  Future<void> _parseChat(Map<String, dynamic> chat) async {
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
        final isOnline = user['is_online'] as bool? ?? false;
        final lastSeenStr = user['last_seen'] as String?;
        setState(() {
          _chatName = user['display_name'] as String? ??
              user['name'] as String? ??
              'User';
          _chatAvatarUrl = user['avatar_url'] as String?;
          _isOnline = isOnline;
          if (!isOnline && lastSeenStr != null) {
            final dt = DateTime.tryParse(lastSeenStr);
            if (dt != null) {
              _lastSeen = _formatLastSeen(dt);
            }
          }
        });
      }
    } else if (chat['name'] != null) {
      setState(() => _chatName = chat['name']);
    }
  }

  String _formatLastSeen(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'last seen just now';
    if (diff.inMinutes < 60) return 'last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'last seen ${diff.inHours}h ago';
    return 'last seen ${dt.day}/${dt.month}';
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider(widget.chatId));
    final controller =
        ref.read(chatControllerProvider(widget.chatId).notifier);

    // Auto-scroll on new messages
    ref.listen<ChatState>(chatControllerProvider(widget.chatId), (prev, next) {
      if (prev != null && next.messages.length > prev.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: _buildAppBar(chatState, controller),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: chatState.isLoading
                ? const MessageListSkeleton()
                : chatState.messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(chatState, controller),
          ),

          // Typing indicator
          if (chatState.typingUsers.isNotEmpty)
            const TypingIndicator(),

          // Reply preview
          if (chatState.replyTo != null)
            ReplyPreviewWidget(
              message: chatState.replyTo!,
              senderName: chatState.replyTo!.senderId == _currentUserId
                  ? 'You'
                  : _chatName,
              isMe: chatState.replyTo!.senderId == _currentUserId,
              onClose: () => controller.clearReply(),
            ),

          // Input bar
          MessageInputBar(
            onSendMessage: (text) {
              if (chatState.editing != null) {
                controller.editMessage(
                    chatState.editing!.messageId, text);
              } else {
                controller.sendMessage(text);
                _scrollToBottom();
              }
            },
            onAttachmentTap: () {
              _showAttachmentPicker();
            },
            onCameraTap: () async {
              final file = await MediaPickerService.instance.pickImage(ImageSource.camera);
              if (file != null) {
                ref.read(chatControllerProvider(widget.chatId).notifier)
                    .sendMediaMessage(file, MessageType.image);
              }
            },
          ),
        ],
      ),

      // Scroll-to-bottom FAB
      floatingActionButton: _showScrollToBottom
          ? Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: FloatingActionButton.small(
                onPressed: () => _scrollToBottom(),
                backgroundColor: AppColors.surfaceDark,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.neonPurple,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(
      ChatState chatState, ChatController controller) {
    final isMultiSelect = chatState.isMultiSelect;

    if (isMultiSelect) {
      return AppBar(
        backgroundColor: AppColors.neonPurple.withValues(alpha: 0.15),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => controller.clearSelection(),
        ),
        title: Text(
          '${chatState.selectedIds.length} selected',
          style: AppTextStyles.labelMedium.copyWith(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: () {
              for (final id in chatState.selectedIds) {
                controller.copyMessage(id);
              }
              controller.clearSelection();
              _showSnackBar('Copied to clipboard');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, size: 20),
            onPressed: () => _showDeleteSelectedDialog(controller),
          ),
          IconButton(
            icon: const Icon(Icons.forward_rounded, size: 20),
            onPressed: () {
              // TODO: forward messages
              controller.clearSelection();
            },
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: AppColors.bgDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {
          // TODO: navigate to contact/chat info
        },
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  AppColors.neonPurple.withValues(alpha: 0.3),
              backgroundImage:
                  _chatAvatarUrl != null ? NetworkImage(_chatAvatarUrl!) : null,
              child: _chatAvatarUrl == null
                  ? Text(
                      _chatName.isNotEmpty
                          ? _chatName[0].toUpperCase()
                          : '?',
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
                    chatState.typingUsers.isNotEmpty
                        ? 'typing...'
                        : _isOnline
                            ? 'Online'
                            : _lastSeen ?? 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: chatState.typingUsers.isNotEmpty
                          ? AppColors.neonCyan
                          : _isOnline
                              ? AppColors.onlineDot
                              : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_rounded, size: 22),
          onPressed: () {
            // TODO: video call
            _showSnackBar('Video call coming soon');
          },
        ),
        IconButton(
          icon: const Icon(Icons.call_rounded, size: 22),
          onPressed: () {
            // TODO: voice call
            _showSnackBar('Voice call coming soon');
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          color: AppColors.surfaceDark,
          onSelected: (value) {
            switch (value) {
              case 'search':
                // TODO: in-chat search
                break;
              case 'mute':
                // TODO: mute chat
                break;
              case 'clear':
                _showClearChatDialog(controller);
                break;
            }
          },
          itemBuilder: (context) => [
            _buildPopupItem('View contact', Icons.person_rounded),
            _buildPopupItem('search', Icons.search_rounded, label: 'Search'),
            _buildPopupItem('mute', Icons.notifications_off_rounded,
                label: 'Mute'),
            _buildPopupItem('Wallpaper', Icons.wallpaper_rounded),
            _buildPopupItem('clear', Icons.delete_sweep_rounded,
                label: 'Clear chat'),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon,
      {String? label}) {
    return PopupMenuItem(
      value: value.toLowerCase(),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label ?? value, style: AppTextStyles.bodyMedium),
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
              gradient: LinearGradient(
                colors: [
                  AppColors.neonPurple.withValues(alpha: 0.2),
                  AppColors.neonCyan.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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

  Widget _buildMessageList(ChatState chatState, ChatController controller) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Load more when scrolled near top
        if (notification is ScrollUpdateNotification &&
            notification.metrics.pixels < 100) {
          controller.loadMoreMessages();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        itemCount: chatState.messages.length,
        itemBuilder: (context, index) {
          final message = chatState.messages[index];
          final isMe = message.senderId == _currentUserId;
          final isSelected = chatState.selectedIds.contains(message.messageId);

          // Check if this is the last message from this sender
          final showTail = index == chatState.messages.length - 1 ||
              chatState.messages[index + 1].senderId != message.senderId;

          // Date separator
          Widget? dateSeparator;
          if (index == 0 ||
              !_isSameDay(chatState.messages[index - 1].timestamp,
                  message.timestamp)) {
            dateSeparator = _buildDateSeparator(message.timestamp);
          }

          return Column(
            children: [
              ?dateSeparator,
              GestureDetector(
                onTap: chatState.isMultiSelect
                    ? () => controller.toggleSelect(message.messageId)
                    : null,
                onLongPress: () {
                  if (chatState.isMultiSelect) {
                    controller.toggleSelect(message.messageId);
                  } else {
                    HapticFeedback.mediumImpact();
                    _showMessageOptions(message, controller);
                  }
                },
                child: Container(
                  color: isSelected
                      ? AppColors.neonPurple.withValues(alpha: 0.12)
                      : Colors.transparent,
                  child: MessageBubble(
                    message: message,
                    isMe: isMe,
                    showTail: showTail,
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      _showMessageOptions(message, controller);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
            style: const TextStyle(
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

  // ─── Message Options Bottom Sheet ─────────────────────────

  void _showMessageOptions(MessageModel message, ChatController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isMe = message.senderId == _currentUserId;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bgDarkTertiary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Quick reactions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['❤️', '😂', '😮', '😢', '🙏', '👍']
                      .map((emoji) => GestureDetector(
                            onTap: () {
                              controller.toggleReaction(
                                  message.messageId, emoji);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                              ),
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          ))
                      .toList(),
                ),
              ),

              Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06)),

              // Options list
              _buildOptionTile(Icons.reply_rounded, 'Reply', () {
                Navigator.pop(context);
                controller.setReplyTo(message);
              }),
              _buildOptionTile(Icons.copy_rounded, 'Copy', () {
                Navigator.pop(context);
                controller.copyMessage(message.messageId);
                _showSnackBar('Copied to clipboard');
              }),
              _buildOptionTile(Icons.forward_rounded, 'Forward', () {
                Navigator.pop(context);
                // TODO: forward flow
              }),
              if (isMe)
                _buildOptionTile(Icons.edit_rounded, 'Edit', () {
                  Navigator.pop(context);
                  controller.setEditing(message);
                }),
              _buildOptionTile(Icons.push_pin_rounded,
                  message.isPinned ? 'Unpin' : 'Pin', () {
                Navigator.pop(context);
                // TODO: pin/unpin
              }),
              _buildOptionTile(Icons.check_box_outlined, 'Select', () {
                Navigator.pop(context);
                controller.toggleSelect(message.messageId);
              }),
              _buildOptionTile(
                Icons.delete_rounded,
                isMe ? 'Delete' : 'Delete for me',
                () {
                  Navigator.pop(context);
                  _showDeleteDialog(message, isMe, controller);
                },
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
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
      dense: true,
    );
  }

  // ─── Dialogs ──────────────────────────────────────────────

  void _showDeleteDialog(
      MessageModel message, bool isMe, ChatController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgDarkTertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete message?',
            style: AppTextStyles.h3.copyWith(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMe)
              _buildDeleteOption(
                'Delete for everyone',
                Icons.public_rounded,
                () {
                  Navigator.pop(context);
                  controller.deleteMessage(message.messageId,
                      forEveryone: true);
                },
              ),
            _buildDeleteOption(
              'Delete for me',
              Icons.person_rounded,
              () {
                Navigator.pop(context);
                controller.deleteMessage(message.messageId);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteOption(
      String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.error, size: 20),
      title: Text(label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _showDeleteSelectedDialog(ChatController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgDarkTertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete selected messages?',
            style: AppTextStyles.h3.copyWith(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteSelected();
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog(ChatController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgDarkTertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear this chat?',
            style: AppTextStyles.h3.copyWith(fontSize: 18)),
        content: Text(
          'All messages will be removed from this device.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: clear chat logic
            },
            child: const Text('Clear',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.bgDarkTertiary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachIcon(Icons.photo_rounded, 'Gallery',
                    AppColors.neonPurple, () async {
                  Navigator.pop(context);
                  final file = await MediaPickerService.instance.pickImage(ImageSource.gallery);
                  if (file != null) {
                    ref.read(chatControllerProvider(widget.chatId).notifier)
                        .sendMediaMessage(file, MessageType.image);
                  }
                }),
                _buildAttachIcon(Icons.camera_alt_rounded, 'Camera',
                    AppColors.neonCyan, () async {
                  Navigator.pop(context);
                  final file = await MediaPickerService.instance.pickImage(ImageSource.camera);
                  if (file != null) {
                    ref.read(chatControllerProvider(widget.chatId).notifier)
                        .sendMediaMessage(file, MessageType.image);
                  }
                }),
                _buildAttachIcon(Icons.description_rounded, 'Document',
                    AppColors.neonOrange, () => Navigator.pop(context)),
                _buildAttachIcon(Icons.location_on_rounded, 'Location',
                    AppColors.neonGreen, () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachIcon(Icons.person_rounded, 'Contact',
                    AppColors.neonBlue, () => Navigator.pop(context)),
                _buildAttachIcon(Icons.poll_rounded, 'Poll',
                    AppColors.neonPink, () => Navigator.pop(context)),
                _buildAttachIcon(Icons.headphones_rounded, 'Audio',
                    AppColors.neonOrange, () => Navigator.pop(context)),
                const SizedBox(width: 60), // spacer
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachIcon(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
