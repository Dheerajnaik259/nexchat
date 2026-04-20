import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../services/media/media_picker_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/message_model.dart';
import '../../../core/constants/route_constants.dart';
import '../../groups/controllers/group_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/reply_preview_widget.dart';
import '../widgets/typing_indicator.dart';
import '../../../core/widgets/skeleton_loader.dart';

/// Group chat screen with real-time messaging
class GroupChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const GroupChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final _supabase = Supabase.instance.client;

  String? _currentUserId;
  String _groupName = 'Group';
  String? _groupAvatarUrl;
  bool _showScrollToBottom = false;
  late Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id;

    _scrollController.addListener(() {
      final show = _scrollController.hasClients &&
          _scrollController.offset <
              _scrollController.position.maxScrollExtent - 200;
      if (show != _showScrollToBottom) {
        setState(() => _showScrollToBottom = show);
      }
    });

    // Mark messages as read
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(groupChatControllerProvider(widget.chatId).notifier)
          .markAsRead();
    });

    _loadGroupInfo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupInfo() async {
    try {
      final group = await _supabase
          .from('chats')
          .select()
          .eq('id', widget.chatId)
          .maybeSingle();

      if (group != null && mounted) {
        setState(() {
          _groupName = group['name'] as String? ?? 'Group';
          _groupAvatarUrl = group['avatar_url'] as String?;
        });

        // Load member names
        final participants =
            List<String>.from(group['participants'] ?? []);
        if (participants.isNotEmpty) {
          final users = await _supabase
              .from('users')
              .select('user_id, display_name, name')
              .inFilter('user_id', participants);

          if (mounted) {
            final names = <String, String>{};
            for (var user in users) {
              final userId = user['user_id'] as String;
              final displayName = user['display_name'] as String? ??
                  user['name'] as String? ??
                  'User';
              names[userId] = displayName;
            }
            setState(() => _userNames = names);
          }
        }
      }
    } catch (e) {
      debugPrint('[GroupChatScreen] Error loading group info: $e');
    }
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
          _scrollController
              .jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(groupChatControllerProvider(widget.chatId));
    final controller = ref.read(
        groupChatControllerProvider(widget.chatId).notifier);

    // Auto-scroll on new messages
    ref.listen<GroupChatState>(
        groupChatControllerProvider(widget.chatId), (prev, next) {
      if (prev != null && next.messages.length > prev.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: _buildAppBar(chatState),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: chatState.isLoadingMessages
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
                  : _userNames[chatState.replyTo!.senderId] ?? 'User',
              isMe: chatState.replyTo!.senderId == _currentUserId,
              onClose: () => controller.clearReply(),
            ),

          // Input bar
          MessageInputBar(
            onSendMessage: (text) {
              if (chatState.editing != null) {
                controller.updateMessage(text);
              } else {
                controller.sendMessage(text);
              }
            },
            onAttachmentPress: () async {
              final file = await MediaPickerService.instance
                  .pickImage(ImageSource.gallery);
              if (file != null) {
                final compressed = await MediaPickerService.instance
                    .compressImage(file);
                if (mounted) {
                  controller.sendMediaMessage(
                      compressed, MessageType.image);
                }
              }
            },
            onCameraPress: () async {
              final photo = await MediaPickerService.instance
                  .pickImage(ImageSource.camera);
              if (photo != null) {
                if (mounted) {
                  controller.sendMediaMessage(
                      photo, MessageType.image);
                }
              }
            },
            isEditing: chatState.editing != null,
            onCancelEdit: () => controller.cancelEditing(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(GroupChatState state) {
    return AppBar(
      backgroundColor: AppColors.bgDarkSecondary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: GestureDetector(
        onTap: () {
          context.pushNamed(
            RouteConstants.groupInfo,
            pathParameters: {'groupId': widget.chatId},
          );
        },
        child: Row(
          children: [
            // Group avatar
            if (_groupAvatarUrl != null)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(_groupAvatarUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgDark,
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: AppColors.neonPurple,
                  size: 20,
                ),
              ),
            const SizedBox(width: 12),
            // Group name and member count
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _groupName,
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                  ),
                ),
                if (state.group != null)
                  Text(
                    '${state.group!.participants.length} members',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white54,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outlined, color: Colors.white),
          onPressed: () {
            context.pushNamed(
              RouteConstants.groupInfo,
              pathParameters: {'groupId': widget.chatId},
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.neonPurple.withValues(alpha: 0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: AppTextStyles.h4.copyWith(
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    GroupChatState state,
    GroupChatController controller,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: state.messages.length + (state.isLoadingMessages ? 1 : 0),
      itemBuilder: (context, index) {
        // Load more indicator at top
        if (index == 0 && state.isLoadingMessages) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.neonPurple,
              ),
            ),
          );
        }

        final actualIndex = state.isLoadingMessages ? index - 1 : index;
        if (actualIndex < 0) return const SizedBox.shrink();

        final message = state.messages[actualIndex];
        final isMe = message.senderId == _currentUserId;
        final senderName =
            _userNames[message.senderId] ?? 'Unknown User';

        return MessageBubble(
          message: message,
          isMe: isMe,
          senderName: isMe ? null : senderName,
          onLongPress: () {
            _showMessageOptions(context, message, controller);
          },
        );
      },
      onNotification: (notification) {
        if (notification is ScrollNotification &&
            notification.metrics.pixels == 0) {
          controller.loadMoreMessages();
        }
        return false;
      },
    );
  }

  void _showMessageOptions(
    BuildContext context,
    MessageModel message,
    GroupChatController controller,
  ) {
    final isMe = message.senderId == _currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDarkSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.reply, color: AppColors.neonPurple),
                title: const Text('Reply'),
                textColor: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  controller.replyToMessage(message);
                },
              ),
            if (isMe && message.type == MessageType.text)
              ListTile(
                leading:
                    const Icon(Icons.edit, color: AppColors.neonPurple),
                title: const Text('Edit'),
                textColor: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  controller.startEditing(message);
                },
              ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete'),
                textColor: Colors.redAccent,
                onTap: () async {
                  Navigator.pop(context);
                  await controller.deleteMessage(
                    message.messageId,
                    forEveryone: false,
                  );
                },
              ),
            ListTile(
              leading:
                  const Icon(Icons.content_copy, color: AppColors.neonPurple),
              title: const Text('Copy'),
              textColor: Colors.white,
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.encryptedText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
