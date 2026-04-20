import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/message_model.dart';
import '../../../services/supabase/database_service.dart';
import '../../../services/supabase/storage_service.dart';

// ─── Chat Controller State ──────────────────────────────────

class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final MessageModel? replyTo;
  final MessageModel? editing;
  final Set<String> selectedIds;
  final List<String> typingUsers;

  const ChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.error,
    this.replyTo,
    this.editing,
    this.selectedIds = const {},
    this.typingUsers = const [],
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    MessageModel? replyTo,
    bool clearReplyTo = false,
    MessageModel? editing,
    bool clearEditing = false,
    Set<String>? selectedIds,
    List<String>? typingUsers,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
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

// ─── Chat Controller (Riverpod Notifier) ─────────────────────

class ChatController extends StateNotifier<ChatState> {
  final String chatId;
  final String currentUserId;
  final _db = DatabaseService.instance;
  final _supabase = Supabase.instance.client;

  RealtimeChannel? _messageChannel;
  RealtimeChannel? _typingChannel;
  Timer? _typingTimer;

  ChatController({
    required this.chatId,
    required this.currentUserId,
  }) : super(const ChatState()) {
    _init();
  }

  void _init() {
    _loadMessages();
    _subscribeToMessages();
    _subscribeToTyping();
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
    super.dispose();
  }

  // ─── Load Messages ───────────────────────────────────────

  Future<void> _loadMessages() async {
    try {
      final messages = await _db.getMessages(chatId, limit: 80);
      // Reverse so oldest is first
      state = state.copyWith(
        messages: messages.reversed.toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages: $e',
      );
    }
  }

  Future<void> loadMoreMessages() async {
    if (state.isLoading) return;
    try {
      final older = await _db.getMessages(
        chatId,
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
        .channel('chat_messages:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            final newMessage = MessageModel.fromJson(payload.newRecord);
            // Avoid duplicates (from optimistic update)
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
            value: chatId,
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
    _typingChannel = _supabase.channel('typing:$chatId');
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
      chatId: chatId,
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

    // Stop typing indicator
    _sendTyping(false);

    try {
      await _db.sendMessage(message);
      state = state.copyWith(isSending: false);
    } catch (e) {
      // Mark as failed
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

    // Optimistic update with local file path preview
    final initialMessage = MessageModel(
      messageId: messageId,
      chatId: chatId,
      senderId: currentUserId,
      type: type,
      encryptedText: '', // Will be updated later if needed
      encryptedMediaUrl: file.path, // Temporary local path
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
      // 1. Upload to Supabase Storage
      final uploadedUrl = await StorageService.instance.uploadChatMedia(
        file: file,
        chatId: chatId,
      );

      // 2. Finalize message and send to DB
      final finalMessage = initialMessage.copyWith(
        encryptedMediaUrl: uploadedUrl,
      );

      await _db.sendMessage(finalMessage);

      // 3. Update local state with real URL
      final idx = state.messages.indexWhere((m) => m.messageId == messageId);
      if (idx != -1) {
        final msgs = List<MessageModel>.from(state.messages);
        msgs[idx] = finalMessage;
        state = state.copyWith(messages: msgs, isSending: false);
      } else {
        state = state.copyWith(isSending: false);
      }

    } catch (e) {
      // Mark as failed
      final idx = state.messages.indexWhere((m) => m.messageId == messageId);
      if (idx != -1) {
        final msgs = List<MessageModel>.from(state.messages);
        msgs[idx] = msgs[idx].copyWith(status: MessageStatus.failed);
        state = state.copyWith(messages: msgs, isSending: false);
      }
    }
  }

  // ─── Edit Message ────────────────────────────────────────

  Future<void> editMessage(String messageId, String newText) async {
    try {
      await _db.updateMessage(messageId, {
        'encrypted_text': newText.trim(),
        'edited': true,
        'edited_at': DateTime.now().toIso8601String(),
      });
      state = state.copyWith(clearEditing: true);
    } catch (e) {
      state = state.copyWith(error: 'Failed to edit message');
    }
  }

  // ─── Delete Message ──────────────────────────────────────

  Future<void> deleteMessage(String messageId, {bool forEveryone = false}) async {
    try {
      await _db.deleteMessage(messageId, forEveryone: forEveryone);
      if (!forEveryone) {
        // Remove locally only
        final msgs = state.messages.where((m) => m.messageId != messageId).toList();
        state = state.copyWith(messages: msgs);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete message');
    }
  }

  // ─── React to Message ───────────────────────────────────

  Future<void> toggleReaction(String messageId, String emoji) async {
    try {
      final msgIdx = state.messages.indexWhere((m) => m.messageId == messageId);
      if (msgIdx == -1) return;

      final message = state.messages[msgIdx];
      final reactions = Map<String, String>.from(message.reactions);

      if (reactions[currentUserId] == emoji) {
        reactions.remove(currentUserId);
      } else {
        reactions[currentUserId] = emoji;
      }

      await _db.updateMessage(messageId, {'reactions': reactions});

      // Optimistic local update
      final msgs = List<MessageModel>.from(state.messages);
      msgs[msgIdx] = message.copyWith(reactions: reactions);
      state = state.copyWith(messages: msgs);
    } catch (e) {
      // Silently fail
    }
  }

  // ─── Copy Message ────────────────────────────────────────

  void copyMessage(String messageId) {
    final msg = state.messages.firstWhere(
      (m) => m.messageId == messageId,
      orElse: () => MessageModel(
        messageId: '',
        chatId: '',
        senderId: '',
        type: MessageType.text,
        encryptedText: '',
        timestamp: DateTime.now(),
      ),
    );
    if (msg.messageId.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: msg.encryptedText));
    }
  }

  // ─── Reply / Edit Selection ─────────────────────────────

  void setReplyTo(MessageModel? message) {
    state = message == null
        ? state.copyWith(clearReplyTo: true)
        : state.copyWith(replyTo: message);
  }

  void setEditing(MessageModel? message) {
    state = message == null
        ? state.copyWith(clearEditing: true)
        : state.copyWith(editing: message);
  }

  void clearReply() => state = state.copyWith(clearReplyTo: true);
  void clearEditing() => state = state.copyWith(clearEditing: true);

  // ─── Multi-Select ────────────────────────────────────────

  void toggleSelect(String messageId) {
    final selected = Set<String>.from(state.selectedIds);
    if (selected.contains(messageId)) {
      selected.remove(messageId);
    } else {
      selected.add(messageId);
    }
    state = state.copyWith(selectedIds: selected);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  Future<void> deleteSelected({bool forEveryone = false}) async {
    for (final id in state.selectedIds) {
      await deleteMessage(id, forEveryone: forEveryone);
    }
    clearSelection();
  }

  // ─── Typing Indicator ───────────────────────────────────

  void onTypingChanged(bool isTyping) {
    _typingTimer?.cancel();
    _sendTyping(isTyping);

    if (isTyping) {
      // Auto-stop after 5 seconds
      _typingTimer = Timer(const Duration(seconds: 5), () {
        _sendTyping(false);
      });
    }
  }

  void _sendTyping(bool isTyping) {
    _typingChannel?.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'user_id': currentUserId,
        'is_typing': isTyping,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ─── Mark as Read ────────────────────────────────────────

  Future<void> markAsRead() async {
    try {
      await _db.markMessagesAsRead(chatId);
    } catch (_) {}
  }
}

// ─── Provider ──────────────────────────────────────────────

final chatControllerProvider = StateNotifierProvider.family<
    ChatController, ChatState, String>((ref, chatId) {
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  return ChatController(chatId: chatId, currentUserId: userId);
});
