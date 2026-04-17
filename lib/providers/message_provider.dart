import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/supabase/database_service.dart';

/// Stream messages for a specific chat (real-time from Supabase)
final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>(
  (ref, chatId) {
    return DatabaseService.instance.streamMessages(chatId);
  },
);

/// Provider to fetch paginated messages (for lazy loading)
final paginatedMessagesProvider = FutureProvider.family<List<MessageModel>, ({String chatId, int offset})>(
  (ref, params) async {
    return DatabaseService.instance.getMessages(
      params.chatId,
      offset: params.offset,
    );
  },
);

/// Typing indicator state for current chat
final typingUsersProvider = StateProvider.family<List<String>, String>(
  (ref, chatId) => [],
);

/// Currently selected message (for reply, forward, etc.)
final replyToMessageProvider = StateProvider<MessageModel?>((ref) => null);

/// Message being edited
final editingMessageProvider = StateProvider<MessageModel?>((ref) => null);

/// Multi-select mode for messages
final selectedMessagesProvider = StateProvider<Set<String>>((ref) => {});

/// Is multi-select mode active
final isMultiSelectModeProvider = Provider<bool>((ref) {
  return ref.watch(selectedMessagesProvider).isNotEmpty;
});
