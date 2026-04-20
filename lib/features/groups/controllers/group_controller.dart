import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/message_model.dart';
import '../../../models/chat_model.dart';
import '../../../services/supabase/database_service.dart';
import '../../../services/supabase/storage_service.dart';

// ─── Group Chat State ──────────────────────────────────────

class GroupChatState {
  final ChatModel? group;
  final List<MessageModel> messages;
  final bool isLoadingGroup;
  final bool isLoadingMessages;
  final bool isSending;
  final String? error;
  final MessageModel? replyTo;
  final MessageModel? editing;
  final Set<String> selectedIds;
  final List<String> typingUsers;

  const GroupChatState({
    this.group,
    this.messages = const [],
    this.isLoadingGroup = true,
    this.isLoadingMessages = true,
    this.isSending = false,
    this.error,
    this.replyTo,
    this.editing,
    this.selectedIds = const {},
    this.typingUsers = const [],
  });

  GroupChatState copyWith({
    ChatModel? group,
    List<MessageModel>? messages,
    bool? isLoadingGroup,
    bool? isLoadingMessages,
    bool? isSending,
    String? error,
    MessageModel? replyTo,
    bool clearReplyTo = false,
    MessageModel? editing,
    bool clearEditing = false,
    Set<String>? selectedIds,
    List<String>? typingUsers,
  }) {
    return GroupChatState(
      group: group ?? this.group,
      messages: messages ?? this.messages,
      isLoadingGroup: isLoadingGroup ?? this.isLoadingGroup,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isSending: isSending ?? this.isSending,
      error: error,
      replyTo: clearReplyTo ? null : (replyTo ?? this.replyTo),
      editing: clearEditing ? null : (editing ?? this.editing),
      selectedIds: selectedIds ?? this.selectedIds,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }

  bool get isMultiSelect => selectedIds.isNotEmpty;
}

// ─── Group Chat Controller (Riverpod Notifier) ──────────────

class GroupChatController extends StateNotifier<GroupChatState> {
  final String groupId;
  final String currentUserId;
  final _db = DatabaseService.instance;
  final _supabase = Supabase.instance.client;

  RealtimeChannel? _messageChannel;
  RealtimeChannel? _typingChannel;
  Timer? _typingTimer;
  StreamSubscription<ChatModel?>? _groupSubscription;

  GroupChatController({
    required this.groupId,
    required this.currentUserId,
  }) : super(const GroupChatState()) {
    _init();
  }

  void _init() {
    _loadGroup();
    _loadMessages();
    _subscribeToMessages();
    _subscribeToTyping();
    _subscribeToGroupUpdates();
  }

  @override
  void dispose() {
    if (_messageChannel != null) {
      _supabase.removeChannel(_messageChannel!);
    }
    if (_typingChannel != null) {
      _supabase.removeChannel(_typingChannel!);
    }
    _typingTimer?.cancel();
    _groupSubscription?.cancel();
    super.dispose();
  }

  // ─── Load Group ──────────────────────────────────────────

  Future<void> _loadGroup() async {
    try {
      final group = await _db.getGroup(groupId);
      state = state.copyWith(group: group, isLoadingGroup: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingGroup: false,
        error: 'Failed to load group: $e',
      );
    }
  }

  // ─── Subscribe to Group Updates ──────────────────────────

  void _subscribeToGroupUpdates() {
    _groupSubscription = _db.streamGroup(groupId).listen((group) {
      state = state.copyWith(group: group);
    });
  }

  // ─── Load Messages ───────────────────────────────────────

  Future<void> _loadMessages() async {
    try {
      final messages = await _db.getMessages(groupId, limit: 80);
      state = state.copyWith(
        messages: messages.reversed.toList(),
        isLoadingMessages: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMessages: false,
        error: 'Failed to load messages: $e',
      );
    }
  }

  Future<void> loadMoreMessages() async {
    if (state.isLoadingMessages) return;
    try {
      final older = await _db.getMessages(
        groupId,
        limit: 40,
        offset: state.messages.length,
      );
      if (older.isNotEmpty) {
        state = state.copyWith(
          messages: [...older.reversed, ...state.messages],
        );
      }
    } catch (e) {
      // Silently fail for pagination
    }
  }

  // ─── Realtime Subscriptions ──────────────────────────────

  void _subscribeToMessages() {
    _messageChannel = _supabase
        .channel('chat_messages:$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: groupId,
          ),
          callback: (payload) {
            final newMessage = MessageModel.fromJson(payload.newRecord);
            if (!state.messages.any((m) => m.messageId == newMessage.messageId)) {
              state = state.copyWith(
                messages: [...state.messages, newMessage],
              );
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: groupId,
          ),
          callback: (payload) {
            final updated = MessageModel.fromJson(payload.newRecord);
            final idx = state.messages.indexWhere(
              (m) => m.messageId == updated.messageId,
            );
            if (idx != -1) {
              final msgs = List<MessageModel>.from(state.messages);
              msgs[idx] = updated;
              state = state.copyWith(messages: msgs);
            }
          },
        )
        .subscribe();
  }

  void _subscribeToTyping() {
    _typingChannel = _supabase.channel('typing:$groupId');
    _typingChannel!.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final userId = payload['user_id'] as String?;
        final isTyping = payload['is_typing'] as bool? ?? false;
        if (userId == null || userId == currentUserId) return;

        final users = List<String>.from(state.typingUsers);
        if (isTyping && !users.contains(userId)) {
          users.add(userId);
        } else if (!isTyping) {
          users.remove(userId);
        }
        state = state.copyWith(typingUsers: users);
      },
    ).subscribe();
  }

  // ─── Send Message ────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final messageId =
        DateTime.now().millisecondsSinceEpoch.toString() +
        currentUserId.substring(0, 4);

    final message = MessageModel(
      messageId: messageId,
      chatId: groupId,
      senderId: currentUserId,
      type: MessageType.text,
      encryptedText: text.trim(),
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      replyToMessageId: state.replyTo?.messageId,
    );

    // Optimistic update
    state = state.copyWith(
      messages: [...state.messages, message],
      isSending: true,
      clearReplyTo: true,
    );

    _sendTyping(false);

    try {
      await _db.sendMessage(message);
      state = state.copyWith(isSending: false);
    } catch (e) {
      final idx = state.messages.indexWhere((m) => m.messageId == messageId);
      if (idx != -1) {
        final msgs = List<MessageModel>.from(state.messages);
        msgs[idx] = msgs[idx].copyWith(status: MessageStatus.failed);
        state = state.copyWith(messages: msgs, isSending: false);
      }
    }
  }

  // ─── Send Media Message ──────────────────────────────────

  Future<void> sendMediaMessage(File file, MessageType type) async {
    final messageId =
        DateTime.now().millisecondsSinceEpoch.toString() +
        currentUserId.substring(0, 4);

    final initialMessage = MessageModel(
      messageId: messageId,
      chatId: groupId,
      senderId: currentUserId,
      type: type,
      encryptedText: '',
      encryptedMediaUrl: file.path,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      replyToMessageId: state.replyTo?.messageId,
    );

    state = state.copyWith(
      messages: [...state.messages, initialMessage],
      isSending: true,
      clearReplyTo: true,
    );
    _sendTyping(false);

    try {
      final uploadedUrl = await StorageService.instance.uploadChatMedia(
        file: file,
        chatId: groupId,
      );

      final finalMessage = initialMessage.copyWith(
        encryptedMediaUrl: uploadedUrl,
      );

      await _db.sendMessage(finalMessage);

      final idx = state.messages.indexWhere((m) => m.messageId == messageId);
      if (idx != -1) {
        final msgs = List<MessageModel>.from(state.messages);
        msgs[idx] = finalMessage;
        state = state.copyWith(messages: msgs, isSending: false);
      } else {
        state = state.copyWith(isSending: false);
      }

    } catch (e) {
      final idx = state.messages.indexWhere((m) => m.messageId == messageId);
      if (idx != -1) {
        final msgs = List<MessageModel>.from(state.messages);
        msgs[idx] = msgs[idx].copyWith(status: MessageStatus.failed);
        state = state.copyWith(messages: msgs, isSending: false);
      }
    }
  }

  // ─── Reply to Message ────────────────────────────────────

  void replyToMessage(MessageModel message) {
    state = state.copyWith(replyTo: message);
  }

  void clearReply() {
    state = state.copyWith(clearReplyTo: true);
  }

  // ─── Edit Message ───────────────────────────────────────

  void startEditing(MessageModel message) {
    state = state.copyWith(editing: message);
  }

  Future<void> updateMessage(String newText) async {
    if (state.editing == null) return;
    
    try {
      await _db.updateMessage(
        state.editing!.messageId,
        {'encrypted_text': newText},
      );
      state = state.copyWith(clearEditing: true);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update message: $e');
    }
  }

  void cancelEditing() {
    state = state.copyWith(clearEditing: true);
  }

  // ─── Delete Message ─────────────────────────────────────

  Future<void> deleteMessage(String messageId, {bool forEveryone = false}) async {
    try {
      await _db.deleteMessage(messageId, forEveryone: forEveryone);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete message: $e');
    }
  }

  // ─── Typing Indicator ────────────────────────────────────

  void _sendTyping(bool isTyping) {
    _typingTimer?.cancel();
    if (!isTyping) {
      try {
        final channel = _supabase.channel('typing:$groupId');
        channel.sendBroadcastMessage(
          event: 'typing',
          payload: {
            'user_id': currentUserId,
            'is_typing': false,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } catch (e) {
        // Silently fail
      }
      return;
    }

    try {
      final channel = _supabase.channel('typing:$groupId');
      channel.sendBroadcastMessage(
        event: 'typing',
        payload: {
          'user_id': currentUserId,
          'is_typing': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Silently fail
    }

    _typingTimer = Timer(const Duration(seconds: 3), () {
      _sendTyping(false);
    });
  }

  void typingStatusChanged(bool isTyping) {
    _sendTyping(isTyping);
  }

  // ─── Mark as Read ───────────────────────────────────────

  Future<void> markAsRead() async {
    try {
      await _db.markMessagesAsRead(groupId);
    } catch (e) {
      // Silently fail
    }
  }

  // ─── Group Actions ──────────────────────────────────────

  Future<bool> leaveGroup() async {
    try {
      await _db.leaveGroup(groupId);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to leave group: $e');
      return false;
    }
  }

  Future<bool> deleteGroup() async {
    try {
      await _db.deleteGroup(groupId);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete group: $e');
      return false;
    }
  }
}

// ─── Riverpod Provider ──────────────────────────────────────

final groupChatControllerProvider =
    StateNotifierProvider.family<GroupChatController, GroupChatState, String>(
  (ref, groupId) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    return GroupChatController(
      groupId: groupId,
      currentUserId: userId,
    );
  },
);
